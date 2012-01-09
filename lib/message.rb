require 'socket'
require 'fileutils'
require 'rubygems'
require 'msgpack'

class Message
  class EventLoop
    def self.start(args={})
      if block_given?
        self.new(args, &Proc.new)
      else
        return self.new(args)
      end
    end

    def initialize(args={})
      path = args[:path] || Message.path(Process.pid)
      FileUtils.rm(path) if File.exist?(path)

      @serv = UNIXServer.new(path)
      FileUtils.chmod(args[:mode] || 0700, path)

      if block_given?
        callback = Proc.new
        begin
          loop(&callback)
        ensure
          close
        end
      end
    end

    def wait(nonblock = false)
      return if stopping?
      s = @serv.__send__(nonblock ? :accept_nonblock : :accept)
      begin
        data = MessagePack.unpack(s.read)
        return yield(*(data.is_a?(Array) ? data : [data])) if block_given?
        return data
      ensure
        s.close
      end
    end

    def peek()
      if block_given?
        return wait(true, &Proc.new)
      else
        return wait(true)
      end
    end

    def loop(&block)
      Kernel.loop do
        break if stopping?
        block.call(self)
      end
    end

    def stop() @stop = true end
    def stopping?() return @stop end

    def close()
      path = @serv.path
      @serv.close
      FileUtils.rm(path)
    end

    private

    def accept() return @serv.accept end

    def accept_nonblock()
      begin
        s = @serv.accept_nonblock
      rescue Errno::EAGAIN
        return nil
      end
    end
  end

  def self.path(pid) return "/tmp/rb_msg_#{pid}" end

  def self.nonblock(args={})
    args[:path] ||= self.path(args[:pid] || Process.pid)
    socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
    sockaddr = [ Socket::AF_UNIX, args[:path] ].pack('S!a108')
    socket.connect_nonblock(sockaddr)
    args[:socket] = socket
    return block_given? ? self.new(args, &Proc.new) : self.new(args)
  end

  def self.send(args, *data)
    args = { :pid => args } if args.is_a?(Fixnum)
    self.new(args){|m| m.send(*data)}
  end

  def self.send_nonblock(args, *data)
    args = { :pid => args } if args.is_a?(Fixnum)
    self.nonblock(args){|m| m.send_nonblock(*args)}
  end

  def initialize(args={})
    path = args[:path] || self.class.path(args[:pid] || Process.pid)
    @socket = args[:socket] || UNIXSocket.new(path)
    if block_given?
      begin
        yield(self)
      ensure
        close
      end
    end
  end

  def send(*args) _send(:write, *args) end
  def send_nonblock(*args) send(:write_nonblock, *args) end
  def close() @socket.close end

  private

  def _send(method, *args) @socket.__send__(method, args.to_msgpack) end
end
