require 'worker'

class Worker
  class DropEffective < Worker
    def [](u)
      u.delete(:eeid)
      return u
    end
  end
end
