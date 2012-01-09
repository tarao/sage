class Worker
  class Compose < Worker
    def initialize(lhs, rhs) @lhs = lhs; @rhs = rhs end
    def to_s() return "#{@rhs}|#{@lhs}" end
    def [](values) return @lhs[@rhs[values]] end
  end

  def <<(other) return Compose.new(other, self) end
  def to_s() return self.class.to_s end
end
