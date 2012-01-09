class Job
  class Queue
    class WatchStatus
      def initialize(pid) @pid = pid end

      def stop()
        Job::Message.send(@pid, :stop)
        Process.waitpid(@pid) rescue nil
      end
    end

    def watch_status(&block)
      pid = fork do
        watch

        Job::Message::EventLoop.start do |ev|
          ev.wait do |m,size|
            case m
            when :stop
              ev.stop
            when :status
              block.call(size)
            end
          end
        end

        unwatch
      end

      return WatchStatus.new(pid)
    end
  end
end
