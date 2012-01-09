require 'worker'

class Worker
  class Id < Worker
    def initialize(val) @val = val end
    def [](x) return @val end
  end
end
