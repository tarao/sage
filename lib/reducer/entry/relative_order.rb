require 'map_reduce'

module MapReduce
  class RelativeOrder < Reducer::Unique
    def ureduce(key, value)
      size = value[:users].size
      size = 1 if size <= 0
      value[:users].each{|u| u[:order] *= 1.0 / size}
      emit(key, value)
    end
  end
end
