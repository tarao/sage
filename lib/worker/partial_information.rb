require 'worker'
require 'hatena/bookmark'

class Worker
  class PartialInformation < Worker
    def [](u)
      Hatena::Bookmark::User.new(u[:user]).partial_information
      return u
    end
  end
end
