require 'map_reduce'

module MapReduce
  class EachUser < Mapper
    def map(key, value)
      value[:users].each do |u|
        val = u.merge(:eid => key)
        val.delete(:user)
        emit(u[:user], val)
      end
    end
  end
end
