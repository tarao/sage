require 'worker'

class Worker
  class WeightMatch < Worker
    def [](u)
      u[:score] *= Math.log((u[:eid]||[]).size+1)
      return u
    end
  end
end
