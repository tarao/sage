require 'worker'

class Worker
  class Accumulate < Worker
    def initialize(key, init=0.0, fun=proc{|r,x|r+x})
      @key = key
      @init = init
      @fun = fun
    end

    def [](values)
      values.each{|v| v[@key] = v[@key].inject(@init, &@fun)}
      return values
    end
  end
end
