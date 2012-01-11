require 'net/http'
require 'uri'
require 'fileutils'
require 'job/queue'
require 'job/runner'
require 'store'
require 'app'

class App
  class HTTP
    class Fetch
      def initialize(uri)
        @uri = uri
      end

      def to_s() return self.class.to_s+"[#{@uri}]" end

      def [](x)
        uri = URI.parse(@uri)

        s = Store.new(App::QUEUE[:http_fetch, :last])
        s.transaction do |db|
          t = db[:timestamp]
          last_uri = db[:uri]

          wait = t + App::HTTP_WAIT - Time.now.to_f
          sleep(wait) if wait > 0

          db[:timestamp] = Time.now.to_f
          db[:uri] = @uri
        end

        http = Net::HTTP.start(uri.host, uri.port)
        res = http.request(Net::HTTP::Get.new(uri.request_uri))
        return res.body if res.code.to_i >= 200 && res.code.to_i < 300
      end
    end

    @@initialized = nil
    @@runner = nil

    def self.init()
      unless @@initialized
        queue, result = [:queue, :result].map{|x| App::QUEUE[:http_fetch, x]}
        dir = File.dirname(queue)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        @@queue = Job::Queue.new(queue, result)
        @@runner = Job::Runner.start(@@queue, 1)
        @@pid = Process.pid

        s = Store.new(App::QUEUE[:http_fetch, :last])
        s.transaction{|db| db[:timestamp] = Time.now.to_f}

        @@initialized = true
      end
    end

    END{ @@runner.stop if @@runner && Process.pid == @@pid }

    def self.fetch(*uris)
      init

      id = @@queue.push(*uris.map{|uri| Fetch.new(uri)}).id
      result = @@queue.wait(id).read
      return result.length <= 1 ? result.first : result
    end
  end
end
