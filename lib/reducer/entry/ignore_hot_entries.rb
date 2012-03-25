require 'map_reduce'
require 'app'

module MapReduce
  class IgnoreHotEntries < Reducer::Unique
    def ureduce(key, value)
      emit(key, value) if value[:count] < App::EFFECTIVE_BOOKMARKS
    end
  end
end
