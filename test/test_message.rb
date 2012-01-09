require 'test/unit'
require File.join(File.dirname($0), 'lib')
require 'message'

class MessageTest < Test::Unit::TestCase
  def setup()
  end

  def teardown()
  end

  def test_event_loop_blocking()
    pid = Process.pid

    fork do
      sleep(0.1) until File.exist?(Message.path(pid))
      Message.send(pid, 'a')
      Message.send(pid, 'b')
      Message.send(pid, 'c')
      Message.send(pid, 'stop')
    end

    result = []
    Message::EventLoop.start do |ev|
      ev.wait do |msg|
        case msg
        when 'stop'
          ev.stop
        else
          result.push(msg)
        end
      end
    end

    assert_equal(['a', 'b', 'c'], result)
  end

  def test_event_loop_blocking_object()
    pid = Process.pid

    fork do
      sleep(0.1) until File.exist?(Message.path(pid))
      Message.send({ :pid => pid }, 'hoge')
      Message.send({ :pid => pid }, 'foo')
      Message.send({ :pid => pid }, [ 'hoge', 'foo' ])
      Message.send({ :pid => pid }, [ 1, 2, 3 ])
      Message.send({ :pid => pid }, 'stop')
    end

    result = []
    Message::EventLoop.start do |ev|
      ev.wait do |msg|
        case msg
        when 'stop'
          ev.stop
        else
          result.push(msg)
        end
      end
    end

    assert_equal(['hoge', 'foo', ['hoge', 'foo'], [1, 2, 3]], result)
  end
end
