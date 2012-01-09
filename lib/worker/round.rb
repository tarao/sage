require 'worker'

class Worker
  class Round < Worker
    def self.round(x, prec=10**3) return (x * prec).round / (1.0 * prec) end

    def initialize(key=key, prec=3) @key = key; @prec = 10**prec end

    def [](values)
      values = [ values ] unless values.is_a?(Array)
      values.each{|v| v[@key] = self.class.round(v[@key], @prec) if v[@key]}
      return values
    end
  end
end
