require 'map_reduce'
require 'hatena/bookmark'

module Scoring
  class ByOrder
    def self.pivot(user, users)
      return users.find_index{|u| u[:user]==user} || users.size-1
    end

    attr_reader :min, :max
    def initialize(user, users)
      @pivot = self.class.pivot(user, users)
      @max = @pivot
      @max = 1 if @max == 0
      @min = @pivot - (users.size-1)
      @min = -@max if @min < -@max
    end

    def [](i, u) return @pivot - ((i - @pivot > @pivot) ? 2*@pivot : i) end
  end

  class ByTime
    def self.pivot(user, users, last)
      return (users.find{|u| u[:user]==user}||{})[:timestamp] || last
    end

    attr_reader :min, :max
    def initialize(user, users)
      now = Time.now.to_i
      first = (users.first||{})[:timestamp] || 0
      last = (users.last||{})[:timestamp] || now

      @pivot = self.class.pivot(user, users, last)
      @max = @pivot - first
      @max = 1 if @max == 0
      @min = @pivot - last
      @min = -@max if @min < -@max
    end

    def [](i, u)
      s = @pivot - u[:timestamp]
      return s < @min ? @min : s
    end
  end

  class ByOrderEffective < ByOrder
    def self.pivot(user, users)
      return users.find_index{|u| !u[:eeid]} || users.size-1
    end
  end

  class ByTimeEffective < ByTime
    def self.pivot(user, users, last)
      return (users.find{|u| !u[:eeid]}||{})[:timestamp] || last
    end
  end

  class Constant
    def initialize(dom) @dom=dom end

    def [](*args)
      o = @dom[*args]
      return 0 if o == 0
      return o < 0 ? -100.0 : 100.0
    end
  end

  class Linear
    def initialize(dom) @dom=dom end
    def [](*args) return @dom[*args] end
  end

  class Cos
    def initialize(dom) @dom=dom end

    def [](*args)
      o = @dom[*args] * Math::PI / @dom.max
      val = if o >= 0
              Math.cos(o + Math::PI) + 1.0
            else
              Math.cos(o) - 1.0
            end
      return val * @dom.max / 2
    end
  end
end

module MapReduce
  class Scoring < Reducer::Unique
    def ureduce(key, value)
      user = context[:user]
      users = value[:users]
      args = context[:scoring]
      reg = args[:regularize]

      dom = args[:dom].new(user, users)
      fun = args[:fun].new(dom)
      users.each_with_index do |u, i|
        score = (u[:user] == user) ? 0 : fun[i, u]
        score = score * 100.0 / dom.max if reg
        u[:score] = score
      end

      emit(key, value)
    end

    class NoPenalty < Reducer::Unique
      def ureduce(key, value)
        value[:users].each{|u| u[:score] = 0 if u[:score] < 0}
        emit(key, value)
      end
    end

    class AllowLate < Reducer::Unique
      def ureduce(key, value)
        value[:users].each{|u| u[:score] = -u[:score] if u[:score] < 0}
        emit(key, value)
      end
    end

    class NUsers < Reducer::Unique
      def ureduce(key, value)
        users = value[:users]
        nusers = users.size
        nusers = 1 if nusers <= 0
        users.each{|u| u[:score] *= nusers}
        emit(key, value)
      end
    end

    class InvNUsers < Reducer::Unique
      def ureduce(key, value)
        users = value[:users]
        nusers = users.size
        nusers = 1 if nusers <= 0
        users.each{|u| u[:score] /= nusers}
        emit(key, value)
      end
    end
  end
end
