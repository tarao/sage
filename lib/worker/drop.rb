require 'worker'

class Worker
  class Drop < Worker
    def initialize(key) @key = key end
    def to_s() return "#{self.class}[#{@key}]" end
    def [](values) values.each{|x| x.delete(@key)}; return values end
  end
end
