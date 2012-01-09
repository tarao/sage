require 'worker'
require 'hatena/bookmark'

class Worker
  class RejectInactive < Worker
    def initialize(threshold) @threshold = threshold end
    def to_s() return "#{self.class}[#{@threshold}]" end

    def [](users)
      return users.reject do |u|
        activity = Hatena::Bookmark::User.new(u[:user]).activity rescue nil
        !activity || activity < @threshold
      end
    end
  end
end
