require 'map_reduce'

module MapReduce
  class MarkOrder < Reducer::Unique
    def ureduce(key, value)
      value[:users].each_with_index{|u,i| u[:order] = i+1}
      emit(key, value)
    end
  end
end
