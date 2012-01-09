require 'worker'

class Worker
  class Top < Worker
    def [](ctx)
      n = ctx[:top][:n]
      key = ctx[:top][:key]
      ctx[key] = ctx[key][0 ... n]
      return ctx
    end
  end
end
