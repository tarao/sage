require 'worker'
require 'hatena/bookmark'

class Worker
  class WeightPrecision < Worker
    def [](x)
      user = Hatena::Bookmark::User.new(x[:user])
      x[:score] /= (1+user.activity)
      return x
    end
  end
end
