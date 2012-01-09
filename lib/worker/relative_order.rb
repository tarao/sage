require 'worker'

class Worker
  class RelativeOrder < Worker
    def [](ctx)
      size = ctx[:users].size
      size = 1 if size <= 0
      ctx[:users].each{|u| u[:order] *= 1.0 / size}
      return ctx
    end
  end
end
