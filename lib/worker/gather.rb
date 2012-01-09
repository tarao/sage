require 'worker'

class Worker
  class Gather < Worker
    def initialize(key) @key = key end

    def to_s() return "#{self.class}[#{@key}]" end

    def [](values)
      result = {}

      values.each do |val|
        x = result[val[@key]] || { @key => val[@key] }
        val.each do |k,v|
          if k != @key
            x[k] = [] unless x[k]
            x[k] << v
          end
        end
        result[val[@key]] = x
      end

      return result.values
    end
  end
end
