require 'worker'
require 'hatena/bookmark'

class Worker
  class WeightPrecision < Worker
    def [](x)
      # user = Hatena::Bookmark::User.new(x[:user])
      # x[:score] /= (1+user.activity)
      user = Hatena::Bookmark::User.new(x[:user])
      activity = user.activity
      x[:score] /= activity if activity >= 1.0
      return x
    end
  end
end
