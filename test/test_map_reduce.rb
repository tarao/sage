require 'test/unit'
require File.join(File.dirname($0), 'lib')
require 'map_reduce'

class Tokenize < MapReduce::Mapper
  def map(key, value) value.split(/\s+/).each{|word| emit(word, 1)} end
end

class Count < MapReduce::Reducer
  def reduce(key, values) emit(key, values.size) end
end

class MapReduceTest < Test::Unit::TestCase
  DATA1 =
    [ [ nil, 'hoge hoge foo bar foo tarao hoge bar bar bar bar bar' ],
    ]

  def test_sequential_map()
    runner = MapReduce::Sequential.new
    result = runner.map(Tokenize.new, DATA1)

    assert_not_nil(result['hoge'])
    assert_kind_of(Array, result['hoge'])
    assert_kind_of(MapReduce::Entry, result['hoge'].first)
    assert_kind_of(Fixnum, result['hoge'].first.value)

    assert_equal([1]*3, result['hoge'].map(&:value))
    assert_equal([1]*2, result['foo'].map(&:value))
    assert_equal([1]*6, result['bar'].map(&:value))
    assert_equal([1]*1, result['tarao'].map(&:value))
  end

  def test_sequential_reduce()
    runner = MapReduce::Sequential.new
    result = runner.reduce(Count.new, runner.map(Tokenize.new, DATA1))

    assert_not_nil(result['hoge'])
    assert_kind_of(Array, result['hoge'])
    assert_kind_of(MapReduce::Entry, result['hoge'].first)

    assert_equal(3, result['hoge'].first.value)
    assert_equal(2, result['foo'].first.value)
    assert_equal(6, result['bar'].first.value)
    assert_equal(1, result['tarao'].first.value)
  end
end
