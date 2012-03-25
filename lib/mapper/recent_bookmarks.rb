require 'map_reduce'
require 'hatena/bookmark'

module MapReduce
  class RecentBookmarks < Mapper
    def map(key, value)
      user = value
      user.recent_bookmarks(context[:recent_bookmarks]).map do |b|
        emit(b['eid'], :uri => b['uri'], :count => b['count'])
      end
    end
  end
end
