require 'worker'

module MapReduce
  class Entry
    attr_reader :key, :value
    def initialize(key, value)
      @key = key
      @value = value
    end

    def <=>(other) return @key <=> other.key end
  end

  class Emitter
    attr_reader :emitted, :context
    def initialize(context=nil)
      @context = context
      @emitted = []
    end

    def emit(key, value) @emitted << Entry.new(key, value) end
    def clear() @emitted = [] end
    def to_s() return self.class.to_s.gsub(/^MapReduce::/, '') end
  end

  class Mapper < Emitter
    def map(key, value) emit(key, value) end

    def [](key, value)
      value = value.first if value.is_a?(Array) && value.size == 1
      value = value.value if value.is_a?(Entry)
      map(key, value)
    end
  end

  class Reducer < Emitter
    def reduce(key, values) emit(key, values) end

    def [](key, values)
      values = values.map{|v| v.is_a?(Entry) ? v.value : v}
      reduce(key, values)
    end

    class List < Reducer
      def initialize(*args) super(); @list = args end
      def to_s() return "#{@list.join('|')}" end
      def reduce(key, values)
        result = @list.inject([[ key, values ]]) do |value,red|
          value.each{|k,v| red[k,v]}
          red.emitted.group_by{|e| e.key}
        end
        @emitted += result.values.flatten
        @list.each{|r| r.clear}
      end
      def +(other) return List.new(*(@list+[other])) end
    end

    def +(other) return List.new(self, other) end

    class Unique < Reducer
      def ureduce(key, value) emit(key, value) end
      def reduce(key, values) ureduce(key, values.first) end
    end
  end

  class Sequential
    def self.start(&block) block.call(self.new) end

    def emit(emitter, args)
      return args unless emitter
      args.each{|k,v| emitter[k, v]}
      return emitter.emitted.group_by{|e| e.key}
    end

    def map(mapper, args) return emit(mapper, args) end
    def reduce(reducer, args) return emit(reducer, args) end
  end

  class JobQueue
    class Worker < ::Worker
      def initialize(emitter, key, value)
        @emitter = emitter
        @key = key
        @value = value
      end

      def to_s() return @emitter.to_s end

      def [](*args)
        @emitter[@key, @value]
        return @emitter.emitted
      end
    end

    def self.start(queue, &block)
      Job::Runner.start(queue) do |runner|
        block.call(self.new(queue))
      end
    end

    def initialize(queue)
      @queue = queue
    end

    def emit(emitter, args)
      return args unless emitter
      ids = args.map{|k,v| @queue.push(Worker.new(emitter, k, v)).id}
      return @queue.wait(*ids).read.inject([]){|r,x|r+x}.group_by{|e| e.key}
    end

    def map(mapper, args) return emit(mapper, args) end
    def reduce(reducer, args) return emit(reducer, args) end
  end
end
