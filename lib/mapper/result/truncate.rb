require 'map_reduce'

module MapReduce
  class Truncate < Mapper
    def map(key, value)
      value = value.sort do |a,b|
        b[1][:score] <=> a[1][:score]
      end[0 ... App::MAX_RESULT]

      value.each{|k,v| emit(k, v)}
    end
  end
end
