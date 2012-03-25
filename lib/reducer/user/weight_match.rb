require 'map_reduce'

module MapReduce
  class WeightMatch < Reducer::Unique
    def ureduce(key, value)
      value[:score] *= Math.log((value[:eid]||[]).size+1)
      emit(key, value)
    end
  end
end
