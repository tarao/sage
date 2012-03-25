require 'map_reduce'

module MapReduce
  class DropEffective < Reducer::Unique
    def ureduce(key, value)
      value.delete(:eeid)
      emit(key, value)
    end
  end
end
