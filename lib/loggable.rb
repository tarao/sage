require 'logger'

module Loggable
  class Logger
    def initialize(klass, *args)
      @klass = klass
      @logger = ::Logger.new(*args)
    end

    def method_missing(name, *args)
      if [ :debug, :info, :warn, :error, :fatal ].include?(name)
        @logger.__send__(name, @klass){ args[0] }
      elsif block_given?
        block = proc
        @logger.__send__(name, *args, &block)
      else
        @logger.__send__(name, *args)
      end
    end
  end

  def log(*args)
    if !args.empty? || @logger == nil
      args << STDERR if args.empty?
      classname = self.is_a?(Class) ? self.to_s : self.class.to_s
      @logger = Logger.new(classname, *args)
      if ENV['DEBUG'].to_i > 1 || $DEBUG
        @logger.level = ::Logger::DEBUG
      elsif ENV['DEBUG'].to_i > 0
        @logger.level = ::Logger::INFO
      else
        @logger.level = ::Logger::WARN
      end
    end
    return @logger
  end

  def debug(msg) log.debug(msg) end
  def info(msg) log.info(msg) end
  def warn(msg) log.warn(msg) end
  def error(msg) log.error(msg) end
  def fatal(msg) log.fatal(msg) end
end
