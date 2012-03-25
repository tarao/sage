require 'map_reduce'
require 'hatena/bookmark'

module MapReduce
  class WeightPrecision < Reducer::Unique
    def ureduce(key, value)
      value[:activity] ||= (Hatena::Bookmark::User.new(key).activity rescue 0)
      activity = value[:activity]
      value[:score] /= (1+activity)
      emit(key, value)
    end
  end
end
