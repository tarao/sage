require 'worker'
require 'hatena/bookmark'

class Worker
  class OrderToScore < Worker
    THRESHOLD = 1.7632228343519

    def [](u)
      u[:score] = 1.0 - u[:order]
      u[:score] = 0.0 if u[:order] >= 0.1

      u[:score] *= (u[:eid]||[]).size

      user = Hatena::Bookmark::User.new(u[:user])
      activity = user.activity
      u[:score] /= activity if activity >= 1.0

      return u
    end
  end
end
