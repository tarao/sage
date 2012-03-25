require 'map_reduce'
require 'app'

module MapReduce
  class IgnoreNicheEntries < Reducer::Unique
    def ureduce(key, value)
      emit(key, value) if value[:count] >= App::EFFECTIVE_BOOKMARKS
    end
  end
end
