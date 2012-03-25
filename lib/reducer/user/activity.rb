require 'map_reduce'
require 'hatena/bookmark'

module MapReduce
  class Activity < Reducer::Unique
    def ureduce(key, value)
      value[:activity] ||= (Hatena::Bookmark::User.new(key).activity rescue 0)
      emit(key, value)
    end
  end
end
