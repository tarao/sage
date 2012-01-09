require 'worker'

class Worker
  class WeightMatch < Worker
    def [](u)
      u[:score] *= Math.log((u[:eid]||[]).size+1)
      # u[:score] *= (u[:eid]||[]).size
      return u
    end
  end
end
