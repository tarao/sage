require 'map_reduce'
require 'hatena/bookmark'

module MapReduce
  class PartialInformation < Reducer::Unique
    def ureduce(key, value)
      Hatena::Bookmark::User.new(key).partial_information
      emit(key, value)
    end
  end
end
