require 'map_reduce'
require 'hatena/bookmark'

module MapReduce
  class Clean < Reducer::Unique
    def ureduce(key, value)
      value[:activity] ||= (Hatena::Bookmark::User.new(key).activity rescue 0)
      activity = value[:activity]
      emit(key, value) if value[:score] > 0 && activity > 0.1
    end
  end
end
