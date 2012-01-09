require 'worker'
require 'hatena/bookmark'

class Worker
  class EntryUsers < Worker
    def [](ctx)
      unless ctx[:eid]
        ctx[:users] = []
        return ctx
      end

      ctx[:users] = Hatena::Bookmark::Entry.new(ctx).users.map do |u|
        { :eid => ctx[:eid], :user => u['user'], :timestamp => u['timestamp'] }
      end.sort{|a,b| a[:timestamp] <=> b[:timestamp]}

      return ctx
    end
  end
end
