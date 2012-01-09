require 'store'
require 'loggable'
require 'job'

class Job
  class Runner
    class Manager
      include Loggable

      def initialize(path)
        @db = Store.new(path)
      end

      def watch(pid)
        @db.transaction do |db|
          handler = db[:watcher] || []
          handler << pid
          db[:watcher] = handler
        end
      end

      def unwatch(pid)
        @db.transaction do |db|
          handler = db[:watcher] || []
          handler.delete(pid)
          db[:watcher] = handler
        end
      end

      def notify_status(size)
        pids = @db.ro.transaction do |db|
          db[:watcher] || []
        end

        pids.each{|pid| Message.notify(pid, :status, size)}
      end

      def register(pid)
        @db.transaction do |db|
          handler = db[:handler] || []
          handler << pid
          db[:handler] = handler
        end
      end

      def unregister(pid)
        @db.transaction do |db|
          handler = db[:handler] || []
          handler.delete(pid)
          db[:handler] = handler
        end
      end

      def notify()
        pid = @db.ro.transaction do |db|
          (db[:handler]||[]).last
        end

        # we cannot use Message.send here because
        # this method may be used by push requests that is called from
        # a running process which is blocking the runner process and
        # causing the backlog limit of ::Message::EventLoop to be exceeded
        Message.notify(pid, :run) if pid
      end

      def new_process(max, &block)
        id = get_new_id(max)
        until id
          debug("resource full")
          Process.wait rescue nil
          id = get_new_id(max)
        end
        debug("allocated resource \##{id}")

        block.call(id)
      end

      def free(id)
        @db.transaction do |db|
          process = db[:process] || []
          process.reject!{|x| x==id}
          db[:process] = process
        end
        debug("deallocated resource \##{id}")
      end

      private

      def get_new_id(max)
        return @db.transaction do |db|
          process = db[:process] || []
          id = (db[:max_id]||0) + 1
          if process.length < max
            process << id
            db[:process] = process
            db[:max_id] = id
            id
          end
        end
      end
    end

    include Loggable

    DEFAULT_MAX_PROCESS = 3

    def self.start(queue, max_process=DEFAULT_MAX_PROCESS)
      runner = self.new(queue, max_process)

      if block_given?
        begin
          yield(runner)
        ensure
          runner.stop
        end
      end

      return runner
    end

    def initialize(queue, max_process=DEFAULT_MAX_PROCESS)
      @manager = queue.runner_manager

      # message handling
      @pid = fork do
        # register the handler
        @manager.register(Process.pid)

        Message::EventLoop.start do |ev|
          until ev.stopping? || queue.empty?
            debug("job found")
            @manager.new_process(max_process) do |id|
              fork do
                debug("spawn new process PID #{Process.pid}")
                queue.run(id)
                debug('job finished')
              end
            end
          end
          ev.wait{|msg| ev.stop if msg == :stop}
        end

        debug('received stop signal')
        Process.waitall # wait for child processes
      end

      info("start runner on PID #{@pid} " +
           "with #{max_process} process#{max_process==1?'':'es'}")
    end

    def stop()
      @manager.unregister(@pid)
      Message.send(@pid, :stop)

      # notify other runners in case this runner is notified to run some jobs
      # but stopped before running them
      @manager.notify

      # wait for running jobs to be done
      debug("waiting for running processes...")
      Process.waitpid(@pid) rescue nil
      info("stopped runner #{@pid}")
    end
  end

  class << Runner; include Loggable end
end
