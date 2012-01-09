require 'worker'
require 'hatena/bookmark'

class Worker
  class Activity < Worker
    def [](u)
      Hatena::Bookmark::User.new(u[:user]).activity
      return u
    end
  end
end
