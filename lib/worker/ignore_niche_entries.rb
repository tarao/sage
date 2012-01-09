require 'worker'
require 'app'

class Worker
  class IgnoreNicheEntries < Worker
    def [](ctx)
      ctx[:eid] = nil if ctx[:count] < App::EFFECTIVE_BOOKMARKS
      return ctx
    end
  end
end
