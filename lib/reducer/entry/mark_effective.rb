require 'map_reduce'

module MapReduce
  class MarkEffective < Reducer::Unique
    def ureduce(key, value)
      user = context[:user]
      value[:users].take(App::EFFECTIVE_BOOKMARKS).take_while do |u|
        u[:user] != user
      end.each do |u|
        u[:eeid] = key
      end
      emit(key, value)
    end
  end
end
