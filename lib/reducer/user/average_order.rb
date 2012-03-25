require 'map_reduce'

module MapReduce
  class AverageOrder < Reducer::Unique
    def ureduce(key, value)
      size = (value[:order]||[]).size
      size = 1 if size <= 0
      value[:order] = (value[:order]||[]).inject(0){|r,x| r+x} * 1.0 / size
      emit(key, value)
    end
  end
end
