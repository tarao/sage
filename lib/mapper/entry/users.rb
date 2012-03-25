require 'map_reduce'
require 'hatena/bookmark'

module MapReduce
  class Users < Mapper
    def map(eid, bookmark)
      arg = bookmark.merge(:eid => eid)
      users = Hatena::Bookmark::Entry.new(arg).users.map do |u|
        { :user => u['user'], :timestamp => u['timestamp'] }
      end.sort{|a,b| a[:timestamp] <=> b[:timestamp]}

      emit(eid, bookmark.merge(:users => users))
    end
  end
end
