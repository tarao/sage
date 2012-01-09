require 'worker'

class Worker
  class MarkEffective < Worker
    def [](ctx)
      user = ctx[:user]

      ctx[:users].take(App::EFFECTIVE_BOOKMARKS).take_while do |u|
        u[:user] != user
      end.each do |u|
        u[:eeid] = u[:eid]
      end

      return ctx
    end
  end
end
