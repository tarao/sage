require 'worker'

class Worker
  class Reject < Worker
    def initialize(pred=nil)
      @pred = pred
      @pred = Proc.new if !pred && block_given?
    end
    def [](values) return values.reject(&@pred) end
  end
end
