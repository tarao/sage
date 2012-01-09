require 'worker'

class Worker
  class Sort < Worker
    def initialize(key, asc=true)  @key = key; @asc = asc end

    def to_s() return "#{self.class}[#{@key},#{@asc ? 'asc' : 'desc'}]" end

    def [](values)
      return values.sort do |a,b|
        x, y = @asc ? [a,b] : [b,a]
        x[@key] <=> y[@key]
      end
    end
  end
end
