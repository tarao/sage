require 'map_reduce'
require 'hatena/bookmark'

module MapReduce
  class OtherEntries < Reducer::Unique
    def ureduce(key, value)
      other_user = Hatena::Bookmark::User.new(key)
      bs = other_user.recent_bookmarks(Hatena::Bookmark::User::SMALL)
      bs = bs.reject{|e| value[:eid].include?(e['eid'])}
      value[:other_entries] = bs[0 ... App::SHOW_OTHER_ENTRIES].map do |b|
        { :eid   => b['eid'], :uri   => b['uri'],
          :title => b['title'], :users => b['count'] }
      end

      emit(key, value)
    end
  end
end
