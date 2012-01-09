require 'time'
require 'loggable'
require 'message'

class Job
  attr_reader :id, :status, :workers, :timestamp
  def initialize(id, *workers)
    @id = id
    @workers = workers
    @timestamp = Time.now.iso8601
  end

  def to_s()
    ws = @workers.map{|w| w.to_s}.join('|')
    return [ '#'+@id.to_s, @timestamp.to_s, ws ].join(' ')
  end

  def run() return @workers.inject(nil){|r,w| w[r]} end

  class Message
    SIGNAL = {
      :stop   => 0,
      :status => 1,
      :run    => 2,
      :finish => 3,
    }
    SIGNAL_INV = SIGNAL.invert

    class EventLoop < ::Message::EventLoop
      def wait(nonblock = false)
        callback = block_given? ? Proc.new : proc{|*x|x}
        super(nonblock) do |*data|
          data[0] = SIGNAL_INV[data[0]]
          res = callback.call(*data)
          return res if block_given?
          return data.length <= 1 ? data.first : data
        end
      end
    end

    def self.send(pid, *args)
      msg = args[0]
      args[0] = SIGNAL[args[0]]
      begin
        debug("send message #{msg.inspect} to PID #{pid}")
        ::Message.new(:pid => pid){|m| m.send(*args)}
      rescue => e
        debug("message #{msg.inspect} to PID #{pid} failed with #{e.class}")
        # ignore
      end
    end

    def self.notify(pid, *args)
      msg = args[0]
      args[0] = SIGNAL[args[0]]
      begin
        debug("notify message #{msg.inspect} to PID #{pid}")
        ::Message.nonblock(:pid => pid){|m| m.send(*args)}
      rescue => e
        debug("message #{msg.inspect} to PID #{pid} failed with #{e.class}")
        # we won't retry even if Errno::EAGAIN is raised
        # since it means the backlog limit of ::Message::EventLoop is exceeded
        # and in that case, ::Message::EventLoop#wait will do something anyway
      end
    end
  end

  class << Message; include Loggable end
end
