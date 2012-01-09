require 'fileutils'
require 'rubygems'
require 'mmap'

class Mmap
  class Object
    def self.load(mmap)
      size = mmap[0...4].unpack('N').first || 0
      if size > 0
        data = mmap[4...size+4]
        return Marshal.load(data)
      end
    end

    def self.store(mmap, obj)
      data = Marshal.dump(obj)
      size = data.size
      mmap[0...4] = [ size ].pack('N')
      mmap.extend(size-mmap.length) if mmap.length < size
      mmap[4...size+4] = data
      mmap.flush
    end

    def initialize(file, mode='r', protection=Mmap::MAP_SHARED, options={})
      FileUtils.touch(file) unless File.exist?(file)
      @mmap = Mmap.new(file, mode, protection, options)
      @obj = self.class.load(@mmap) || {}
    end

    def [](*keys)
      return keys.inject(@obj){|r,x| (r||{})[x.to_s]}
    end

    def []=(key, val)
      @obj[key.to_s] = val
      return self
    end

    def flush() self.class.store(@mmap, @obj) end
  end
end
