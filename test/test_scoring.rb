require 'test/unit'
require File.join(File.dirname($0), 'lib')
require 'worker/id'
require 'worker/scoring'
require 'loggable'

class ScoringTest < Test::Unit::TestCase
  include Loggable

  DATA =
    [ { :user => 'foo', :timestamp => 100 },
      { :user => 'bar', :timestamp => 110 },
      { :user => 'baz', :timestamp => 190 },
      { :user => 'qux', :timestamp => 200 },
      { :user => 'hoge', :timestamp => 290 },
      { :user => 'piyo', :timestamp => 301 },
      { :user => 'fuga', :timestamp => 320 },
    ]

  DELTA = 0.00001

  def test_order_linear1()
    ctx = {
      :user    => 'qux',
      :users   => DATA,
      :scoring => {
        :dom => Scoring::ByOrder, :fun => Scoring::Linear, :regularize => true,
      },
    }
    s = Worker::Id.new(ctx) << Worker::Scoring.new
    result = s[nil][:users]
    assert_equal(DATA.size, result.size)
    assert_in_delta(100.0, result.first[:score], DELTA)
    assert_in_delta(-100.0, result.last[:score], DELTA)
    assert_equal(0, result[3][:score])

    last = nil
    result.each do |r|
      info(r.inspect)
      assert(r[:score] <= last[:score]) if last
      last = r
    end
  end

  def test_order_linear2()
    ctx = {
      :user    => 'baz',
      :users   => DATA,
      :scoring => {
        :dom => Scoring::ByOrder, :fun => Scoring::Linear, :regularize => true,
      },
    }
    s = Worker::Id.new(ctx) << Worker::Scoring.new
    result = s[nil][:users]
    assert_equal(DATA.size, result.size)
    assert_in_delta(100.0, result.first[:score], DELTA)
    assert_in_delta(-100.0, result.last[:score], DELTA)
    assert_equal(0, result[2][:score])

    last = nil
    result.each do |r|
      info(r.inspect)
      assert(r[:score] <= last[:score]) if last
      last = r
    end
  end

  def test_time_linear1()
    ctx = {
      :user    => 'qux',
      :users   => DATA,
      :scoring => {
        :dom => Scoring::ByTime, :fun => Scoring::Linear, :regularize => true,
      },
    }
    s = Worker::Id.new(ctx) << Worker::Scoring.new
    result = s[nil][:users]
    assert_equal(DATA.size, result.size)
    assert_in_delta(100.0, result.first[:score], DELTA)
    assert_in_delta(-100.0, result.last[:score], DELTA)
    assert_equal(0, result[3][:score])

    last = nil
    result.each do |r|
      info(r.inspect)
      assert(r[:score] <= last[:score]) if last
      last = r
    end
  end

  def test_time_linear2()
    ctx = {
      :user    => 'baz',
      :users   => DATA,
      :scoring => {
        :dom => Scoring::ByTime, :fun => Scoring::Linear, :regularize => true,
      },
    }
    s = Worker::Id.new(ctx) << Worker::Scoring.new
    result = s[nil][:users]
    assert_equal(DATA.size, result.size)
    assert_in_delta(100.0, result.first[:score], DELTA)
    assert_in_delta(-100.0, result.last[:score], DELTA)
    assert_equal(0, result[2][:score])

    last = nil
    result.each do |r|
      info(r.inspect)
      assert(r[:score] <= last[:score]) if last
      last = r
    end
  end

  def test_order_cos1()
    ctx = {
      :user    => 'qux',
      :users   => DATA,
      :scoring => {
        :dom => Scoring::ByOrder, :fun => Scoring::Cos, :regularize => true,
      },
    }
    s = Worker::Id.new(ctx) << Worker::Scoring.new
    result = s[nil][:users]
    assert_equal(DATA.size, result.size)
    assert_in_delta(100.0, result.first[:score], DELTA)
    assert_in_delta(-100.0, result.last[:score], DELTA)
    assert_equal(0, result[3][:score])

    last = nil
    result.each do |r|
      info(r.inspect)
      assert(r[:score] <= last[:score]) if last
      last = r
    end
  end

  def test_order_cos2()
    ctx = {
      :user    => 'baz',
      :users   => DATA,
      :scoring => {
        :dom => Scoring::ByOrder, :fun => Scoring::Cos, :regularize => true,
      },
    }
    s = Worker::Id.new(ctx) << Worker::Scoring.new
    result = s[nil][:users]
    assert_equal(DATA.size, result.size)
    assert_in_delta(100.0, result.first[:score], DELTA)
    assert_in_delta(-100.0, result.last[:score], DELTA)
    assert_equal(0, result[2][:score])

    last = nil
    result.each do |r|
      info(r.inspect)
      assert(r[:score] <= last[:score]) if last
      last = r
    end
  end

  def test_time_cos1()
    ctx = {
      :user    => 'qux',
      :users   => DATA,
      :scoring => {
        :dom => Scoring::ByTime, :fun => Scoring::Cos, :regularize => true,
      },
    }
    s = Worker::Id.new(ctx) << Worker::Scoring.new
    result = s[nil][:users]
    assert_equal(DATA.size, result.size)
    assert_in_delta(100.0, result.first[:score], DELTA)
    assert_in_delta(-100.0, result.last[:score], DELTA)
    assert_equal(0, result[3][:score])

    last = nil
    result.each do |r|
      info(r.inspect)
      assert(r[:score] <= last[:score]) if last
      last = r
    end
  end

  def test_time_cos2()
    ctx = {
      :user    => 'baz',
      :users   => DATA,
      :scoring => {
        :dom => Scoring::ByTime, :fun => Scoring::Cos, :regularize => true,
      },
    }
    s = Worker::Id.new(ctx) << Worker::Scoring.new
    result = s[nil][:users]
    assert_equal(DATA.size, result.size)
    assert_in_delta(100.0, result.first[:score], DELTA)
    assert_in_delta(-100.0, result.last[:score], DELTA)
    assert_equal(0, result[2][:score])

    last = nil
    result.each_with_index do |r,i|
      info(r.inspect)
      assert(r[:score] <= last[:score]) if last
      last = r
    end
  end
end
