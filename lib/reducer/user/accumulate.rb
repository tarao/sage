require 'map_reduce'

module MapReduce
  class Accumulate < Reducer
    def reduce(key, values)
      result = {}
      values.each do |val|
        val.each do |k,v|
          result[k] = [] unless result[k]
          result[k] << v
        end
      end

      result[:score] ||= []
      result[:score] = result[:score].inject(0.0){|r,x| r+x}
      result.delete(:timestamp)

      emit(key, result) if result[:score] > 0
    end
  end
end
