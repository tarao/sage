require 'strscan'
require 'app'
require 'store'
require 'message'
require 'job/queue'
require 'job/runner'
require 'algorithm'
require 'worker/batch'

class App
  RUN_SIGNAL = {
    :start               => 0,
    :already_running     => 1,
    :too_many_processes  => 2,
    :size_limit_exceeded => 3,
  }

  RUN_ERROR = {
    :already_running    => "There are running batch processes for %s",
    :too_many_processes => "There are too many running batch processes (%s)",
    :size_limit_exceeded => "Size limit exceeded",
  }

  class Sender
    def initialize(pid) @pid=pid end
    def send(val) Message.send(@pid, val) end

    class Nil; def send(val) end end
  end

  class << self
    def run(user, nonblock=true)
      if nonblock
        sender = Sender.new(Process.pid)
        Message::EventLoop.start do |ev|
          fork{ run_(user, sender) }
          val = ev.wait{|val| ev.stop; return val}
        end
      else
        return run_(user, Sender::Nil.new)
      end
    end

    private

    def check_size()
      size = StringScanner.new(`du -sk "#{DB[]}"`).scan(/\d+/).to_i
      return size <= MAX_DISK_USAGE
    end

    def run_(u, signal)
      unless check_size
        err = :size_limit_exceeded
        signal.send(RUN_SIGNAL[err])
        STDERR.puts(RUN_ERROR[err])
        return RUN_SIGNAL[err]
      end

      semaphore = Semaphore.new(u)

      reqs = semaphore.p
      if reqs
        err = if reqs.include?(u)
                reqs = [ u ]
                :already_running
              else
                :too_many_processes
              end
        STDERR.puts(RUN_ERROR[err] % reqs.join(', '))
        signal.send(RUN_SIGNAL[err])
        return RUN_SIGNAL[err]
      end

      signal.send(RUN_SIGNAL[:start])

      begin
        path = Path.new(u, nil)
        queue = Job::Queue.new(path.global.queue, path.global.result)

        Job::Runner.start(queue, BATCH_PROCESSES) do |runner|
          ids = Algorithm::DESCRIPTION.map do |k,d|
            queue.push(Worker::Batch.new(u, k)).id
          end
          queue.wait(*ids).read
        end
      ensure
        semaphore.v
      end

      return RUN_SIGNAL[:start]
    end
  end
end
