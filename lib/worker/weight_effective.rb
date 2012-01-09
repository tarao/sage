require 'worker'

class Worker
  class WeightEffective < Worker
    def [](u)
      u[:score] *= Math.log((u[:eeid]||[]).size+1)
      return u
    end
  end
end
