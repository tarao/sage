require 'worker'
require 'hatena/bookmark'

class Worker
  class OtherEntries < Worker
    def [](u)
      other_user = Hatena::Bookmark::User.new(u[:user])
      bs = other_user.recent_bookmarks(Hatena::Bookmark::User::SMALL)
      bs = bs.reject{|e| u[:eid].include?(e['eid'])}
      u[:other_entries] = bs[0 ... App::SHOW_OTHER_ENTRIES].map do |b|
        { :eid   => b['eid'], :uri   => b['uri'],
          :title => b['title'], :users => b['count'] }
      end
      return u
    end
  end
end
