require 'map_reduce'
require 'hatena/bookmark'

module MapReduce
  class OrderToScore < Reducer::Unique
    def ureduce(key, value)
      u = value
      u[:score] = 1.0 - u[:order]
      u[:score] = 0.0 if u[:order] >= 0.1

      u[:score] *= (u[:eid]||[]).size

      value[:activity] ||= (Hatena::Bookmark::User.new(key).activity rescue 0)
      activity = value[:activity]
      u[:score] /= activity if activity >= 1.0

      emit(key, value)
    end
  end
end
