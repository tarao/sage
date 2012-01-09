require 'pstore'
require 'yaml/store'

class Store
  def initialize(file, readonly=false)
    @file = file.to_s
    @store = nil
    @readonly = readonly
  end

  def store_class() return PStore end

  def path() return @file end

  def ro() return self.class.new(path, true) end

  def transaction(readonly=nil, &block)
    begin
      @store = store_class.new(@file)
      @store.transaction((readonly==nil && @readonly) || readonly) do
        block.call(self)
      end
    ensure
      @store = nil
    end
  end

  def [](*keys)
    return keys.inject(@store){|r,x| (r||{})[x.to_s]}
  end

  def []=(key, val)
    @store[key.to_s] = val
    return self
  end

  class YAML < Store
    def store_class() return ::YAML::Store end
  end

  class Mmap < Store
    def initialize(file, readonly=false)
      require 'mmap/object'
      @mfile = file.to_s
      super(@mfile + '.lock', readonly)
    end

    def path() return @mfile end

    def transaction(readonly=nil, &block)
      super(readonly) do |lock|
        readonly = (readonly==nil && @readonly) || readonly
        mobj = ::Mmap::Object.new(@mfile, 'rw')
        block.call(mobj).tap{ mobj.flush unless readonly }
      end
    end
  end
end
