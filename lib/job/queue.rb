require 'store'
require 'loggable'
require 'job'
require 'job/runner'

class Job
  class Result
    def initialize(db, ids)
      @db = db
      @ids = ids
    end

    def read(del=true)
      r=[]
      (del ? @db : @db.ro).transaction do |db|
        result = db[:result] || {}
        @ids.each do |id|
          r.push(result[id]) if result[id]
          result.delete(id)
        end
        db[:result] = result if del
      end
      return r
    end

    def peek() return read(false) end
  end

  class Queue
    include Loggable

    def initialize(queue, result=nil)
      @queue = Store.new(queue)
      @result = Store.new(result || queue)
    end

    def runner_manager_path()
      path = @queue.path
      fname = [ File.basename(path, '.*'), 'runner' ].join('.')
      fname += File.extname(path)
      return File.join(File.dirname(path), fname)
    end

    def runner_manager()
      return Runner::Manager.new(runner_manager_path)
    end

    def to_s()
      return @queue.ro.transaction do |db|
        (db[:queue] || []).map{|j| j.to_s}
      end
    end

    def count()
      return @queue.ro.transaction do |db|
        (db[:queue] || []).length
      end
    end

    def empty?() return count <= 0 end

    def clear()
      @queue.transaction do |db|
        db[:jobs] = {}
        db[:queue] = []
        db[:max_id] = 0
      end

      info("cleared queue #{@queue.path}")
    end

    def push(*workers)
      job, size = @queue.transaction do |db|
        id = (db[:max_id]||0) + 1
        j = Job.new(id, *workers)

        jobs = db[:jobs] || {}
        q = db[:queue] || []

        jobs[id] = true
        q.push(j)

        db[:max_id] = id
        db[:queue] = q
        db[:jobs] = jobs

        [ j, q.size ]
      end
      info("pushed job #{job} into #{@queue.path}")

      runner_manager.notify_status(size)
      runner_manager.notify
      return job
    end

    def run(id)
      begin
        job, size = @queue.transaction do |db|
          q = db[:queue] || []
          [ q.shift, q.size ]
        end
        info("popped job #{job} from #{@queue.path}")
        runner_manager.notify_status(size)

        return unless job
        info("run job #{job}")
        begin
          r = job.run
        rescue => e
          info(e.to_s)
          info(e.backtrace.join("\n"))
        rescue Timeout::Error => e
          info(e.to_s)
          info(e.backtrace.join("\n"))
        end

        if r
          @result.transaction do |db|
            result = db[:result] || {}
            result[job.id] = r
            db[:result] = result
          end
        end

        @queue.transaction do |db|
          jobs = db[:jobs] || {}
          jobs.delete(job.id)
          db[:jobs] = jobs
        end

        h = @result.ro.transaction do |db|
          handler = db[:handler] || {}
          handler[job.id] || []
        end
        h.each{|pid| Message.notify(pid, :finish)}

        return [ job, r ]
      ensure
        runner_manager.free(id)
      end
    end

    def wait(*ids)
      block = block_given? ? Proc.new : proc{|x|x}

      check_running = proc do
        @queue.ro.transaction do |db|
          jobs = db[:jobs] || {}
          ids.find{|id| jobs[id]}
        end
      end

      # message handling
      pid = fork do
        debug("waiting for result on PID #{Process.pid}")

        # register the handler
        @result.transaction do |db|
          handler = db[:handler] || {}
          ids.each do |id|
            handler[id] ||= []
            handler[id] << Process.pid
          end
          db[:handler] = handler
        end

        Message::EventLoop.start do |ev|
          ev.stop unless check_running[]
          ev.wait
        end
      end

      # wait for the handler
      Process.waitpid(pid)

      # unregister the handler
      @result.transaction do |db|
        handler = db[:handler] || {}
        ids.each do |id|
          h = handler[id] || []
          h.delete(pid)
          handler.delete(id) if h.empty?
        end
        db[:handler] = handler
      end
      info("finished job \##{ids.join(',')} on #{@queue.path}")

      return block.call(Result.new(@result, ids))
    end

    def watch() runner_manager.watch(Process.pid) end
    def unwatch() runner_manager.watch(Process.pid) end
  end
end
