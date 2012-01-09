require 'worker'

class Worker
  class Pick < Worker
    def initialize(key) @key = key end
    def [](ctx) return ctx[@key] end
  end
end
