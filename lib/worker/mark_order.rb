require 'worker'

class Worker
  class MarkOrder < Worker
    def [](ctx)
      ctx[:users].each_with_index{|u,i| u[:order] = i+1}
      return ctx
    end
  end
end
