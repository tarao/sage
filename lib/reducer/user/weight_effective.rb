require 'map_reduce'

module MapReduce
  class WeightEffective < Reducer::Unique
    def ureduce(key, value)
      value[:score] *= Math.log((value[:eeid]||[]).size+1)
      emit(key, value)
    end
  end
end
