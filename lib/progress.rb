class Progress
  attr_reader :max, :step, :msg
  def initialize(phase=nil)
    @max = phase
    @step = 0
    @msg = nil
  end

  def to_i() return step end
  def to_r() return step.quo(max) end

  def msg!(msg) @msg = msg end
  def inc!() @step += 1 end
  def set!(val=0) @step = val end

  def clear!()
    @setp = 0
    @msg = nil
  end

  class Diff < Progress
    def set!(val=0)
      @last = @last || 0

      if val < @last
        @step += @last - val
      elsif @last < val
        @max += val - @last
      end
      @last = val
    end

    def clear!()
      @last = 0
      super
    end
  end

  class Store
    def initialize(db, id, progress=nil)
      @db = db
      @id = id
      @progress = progress
      unless @progress
        @progress = @db.ro.transaction{|db| db[@id]}
      end
    end

    def method_missing(m, *args)
      r = @progress.__send__(m, *args)
      save if m.to_s =~ /!$/
      return r
    end

    def save() @db.transaction{|db| db[@id] = @progress} end
    def loaded?() return @progress != nil end
  end
end
