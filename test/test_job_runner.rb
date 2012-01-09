require 'test/unit'
require File.join(File.dirname($0), 'lib')
require 'job/queue'
require 'fileutils'

def watch_status(queue, &block)
  pid = fork do
    queue.watch

    len=0
    puts
    Job::Message::EventLoop.start do |ev|
      ev.wait do |m,size|
        if m == :stop
          ev.stop
        elsif m == :status
          len = [ size.to_s.length, len ].max
          print(size > 0 ? "\r#{size}#{' '*(len-size.to_s.length)}" : "\r")
          STDOUT.flush
        end
      end
    end

    queue.unwatch
  end

  begin
    block.call
  ensure
    Job::Message.send(pid, :stop)
    Process.waitpid(pid) rescue nil
  end
end

class Worker
  def initialize(arg)
    @arg = arg
  end

  def [](r) return (r||'')+@arg end

  def to_s() return @arg end
end

class JobRunnerTest < Test::Unit::TestCase
  QUEUE = 'test_queue.db'
  RESULT = 'test_result.db'
  RUNNER = 'test_queue.runner.db'

  FILES = [ QUEUE, QUEUE+'.lock', RESULT, RESULT+'.lock', RUNNER ]

  WORKERS1 =
    [
     [ 'hoge', 'foo', 'bar' ],
     [ 'hoge', 'foo', 'bar', 'tarao' ],
     [ 'a', 'b', 'c', 'd' ],
     [ 'a' ],
    ]

  WORKERS2 =
    [
     [ 'a' ],
     [ 'a', 'b' ],
     [ 'a', 'b', 'c' ],
     [ 'a', 'b', 'c', 'd' ],
     [ 'a', 'b', 'c', 'd', 'e' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q', 'r' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q', 'r', 's' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q', 'r', 's', 't' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q', 'r', 's', 't', 'u' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y' ],
     [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
       'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' ],
    ]

  def setup()
    FILES.each{|f| FileUtils.touch(f)}
  end

  def teardown()
    FILES.each{|f| FileUtils.rm(f)}
  end

  def test_run1()
    queue = Job::Queue.new(QUEUE, RESULT)
    watch_status(queue) do
      Job::Runner.start(queue) do |runner|
        ids = WORKERS1.map do |w|
          queue.push(*w.map{|x| Worker.new(x)}).id
        end

        tests = 0

        queue.wait(*ids) do |result|
          result.read.each_with_index do |x,i|
            tests = tests+1
          assert_equal(WORKERS1[i].join(''), x)
          end
        end

        assert_equal(WORKERS1.size, tests)
      end
    end
  end

  def test_run1_single_process()
    queue = Job::Queue.new(QUEUE, RESULT)
    watch_status(queue) do
      Job::Runner.start(queue, 1) do |runner|
        ids = WORKERS1.map do |w|
          queue.push(*w.map{|x| Worker.new(x)}).id
        end

        tests = 0

        queue.wait(*ids) do |result|
          result.read.each_with_index do |x,i|
            tests = tests+1
            assert_equal(WORKERS1[i].join(''), x)
          end
        end

        assert_equal(WORKERS1.size, tests)
      end
    end
  end

  def test_run1_push_first()
    queue = Job::Queue.new(QUEUE, RESULT)
    watch_status(queue) do
      ids = WORKERS1.map do |w|
        queue.push(*w.map{|x| Worker.new(x)}).id
      end

      Job::Runner.start(queue) do |runner|
        tests = 0

        queue.wait(*ids) do |result|
          result.read.each_with_index do |x,i|
            tests = tests+1
            assert_equal(WORKERS1[i].join(''), x)
          end
        end

        assert_equal(WORKERS1.size, tests)
      end
    end
  end

  def test_run2()
    queue = Job::Queue.new(QUEUE, RESULT)
    watch_status(queue) do
      Job::Runner.start(queue, 4) do |runner|
        ids = WORKERS2.map do |w|
          queue.push(*w.map{|x| Worker.new(x)}).id
        end

        tests = 0

        queue.wait(*ids) do |result|
          result.read.each_with_index do |x,i|
            tests = tests+1
            assert_equal(WORKERS2[i].join(''), x)
          end
        end

        assert_equal(WORKERS2.size, tests)
      end
    end
  end

  def test_run2_single_process()
    queue = Job::Queue.new(QUEUE, RESULT)
    watch_status(queue) do
      Job::Runner.start(queue, 1) do |runner|
        ids = WORKERS2.map do |w|
          queue.push(*w.map{|x| Worker.new(x)}).id
        end

        tests = 0

        queue.wait(*ids) do |result|
          result.read.each_with_index do |x,i|
            tests = tests+1
            assert_equal(WORKERS2[i].join(''), x)
          end
        end

        assert_equal(WORKERS2.size, tests)
      end
    end
  end

  def test_run2_push_first()
    queue = Job::Queue.new(QUEUE, RESULT)
    watch_status(queue) do
      ids = WORKERS2.map do |w|
        queue.push(*w.map{|x| Worker.new(x)}).id
      end

      Job::Runner.start(queue, 4) do |runner|
        tests = 0

        queue.wait(*ids) do |result|
          result.read.each_with_index do |x,i|
            tests = tests+1
            assert_equal(WORKERS2[i].join(''), x)
          end
        end

        assert_equal(WORKERS2.size, tests)
      end
    end
  end

  def test_run2_multiple_runners()
    queue = Job::Queue.new(QUEUE, RESULT)
    watch_status(queue) do
      Job::Runner.start(queue, 4) do |runner1|
        Job::Runner.start(queue, 4) do |runner2|
          ids = WORKERS2.map do |w|
            queue.push(*w.map{|x| Worker.new(x)}).id
          end

          tests = 0

          queue.wait(*ids) do |result|
            result.read.each_with_index do |x,i|
              tests = tests+1
              assert_equal(WORKERS2[i].join(''), x)
            end
          end

          assert_equal(WORKERS2.size, tests)
        end
      end
    end
  end

  SYNC =
    [
     [ 1, 2, 3, 5, 8, 13, 21 ],
     [ 2, 3, 5, 7, 11, 13, 17, 19, 23 ],
    ]

  def test_run2_multi_sync()
    queue = Job::Queue.new(QUEUE, RESULT)
    watch_status(queue) do
      ids = WORKERS2.map do |w|
        queue.push(*w.map{|x| Worker.new(x)}).id
      end

      Job::Runner.start(queue, 4) do |runner|
        SYNC.each do |idx|
          tests = 0
          queue.wait(*idx.map{|i| ids[i]}) do |result|
            result.peek.each_with_index do |x,i|
              tests = tests+1
              assert_equal(WORKERS2[idx[i]].join(''), x)
            end
          end
          assert_equal(idx.size, tests)
        end

        tests = 0
        queue.wait(*ids) do |result|
          result.read.each_with_index do |x,i|
            tests = tests+1
            assert_equal(WORKERS2[i].join(''), x)
          end
          assert(result.read.empty?)
        end

        assert_equal(WORKERS2.size, tests)
      end
    end
  end
end
