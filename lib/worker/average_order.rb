require 'worker'
require 'hatena/bookmark'

class Worker
  class AverageOrder < Worker
    def [](u)
      size = (u[:order]||[]).size
      size = 1 if size <= 0
      u[:order] = (u[:order]||[]).inject(0){|r,x| r+x} * 1.0 / size
      return u
    end
  end
end
