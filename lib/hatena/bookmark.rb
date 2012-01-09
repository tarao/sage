require 'app/http'
require 'uri'
require 'time'
require 'fileutils'
require 'rss'
require 'rubygems'
require 'json'
require 'nokogiri'

module Hatena
  class Bookmark
    class UserRssXml
      XPATH = {
        :total => './/opensearch:totalResults',
        :count => './/xmlns:item/xmlns:link[.="%s"]/../hatena:bookmarkcount',
      }

      def initialize(raw_rss)
        @xml = Nokogiri::XML.parse(raw_rss)
        @ns = @xml.collect_namespaces
      end

      def search(xpath) return @xml.at(xpath, @ns) end
      def total() return search(XPATH[:total]).text.to_i rescue -1 end
      def count(uri) return search(XPATH[:count] % uri).text.to_i rescue 0 end
    end

    class API
      URI = {
        :user_rss => 'http://b.hatena.ne.jp/%s/rss?of=%i',
        :entry    => 'http://b.hatena.ne.jp/entry/jsonlite/?url=%s',
        :partial_information => 'http://b.hatena.ne.jp/%s/partial.information',
      }

      def self.user_rss(user, size)
        i=0
        entries = []
        channel = nil
        total = nil
        loop do
          res = App::HTTP.fetch(URI[:user_rss] % [ user, i ])
          rss = RSS::Parser.parse(res)
          xml = UserRssXml.new(res)
          total = xml.total unless total
          channel = rss.channel unless channel
          entries += rss.items.map do |e|
            e.instance_eval{ @count = xml.count(link) }
            def e.count() return @count end
            e
          end
          i += rss.items.size
          break if i >= size
        end
        return {
          :total => total,
          :channel => channel,
          :items => entries[0...size]
        }
      end

      def self.entry(uri)
        encoded = ::URI::encode(uri, /[^-.,:a-zA-Z0-9_\/]/)
        res = App::HTTP.fetch(URI[:entry] % encoded)
        begin
          return JSON.parse(res)
        rescue
          warn("failed to fetch entry for #{uri}")
          return {}
        end
      end

      def self.partial_information(user)
        return App::HTTP.fetch(URI[:partial_information] % user)
      end
    end

    class << API; include Loggable end

    def self.save(file, data)
      FileUtils.mkdir_p(File.dirname(file))
      open(file, 'w'){|io| io.write(data)}
    end

    DEFAULT_CONV = {
      :dump => proc{|x|x}, :load => proc{|x|x}
    }
    JSON_CONV = {
      :dump => :to_json.to_proc, :load => JSON.method(:parse)
    }

    def self.read(file, conv=DEFAULT_CONV, &fetch_new)
      return conv[:load][IO.read(file)] if App.up_to_date?(file)
      res = fetch_new.call
      self.save(file, conv[:dump][res])
      return res
    end

    def self.read_json(file, &fetch_new)
      return read(file, JSON_CONV, &fetch_new)
    end

    class Entry
      def self.fname(eid)
        return App::ENTRIES[(eid.to_i % 100).to_s.rjust(2, '0'), eid]
      end

      def self.cached_fetch(uri, eid)
        retrieve = proc{ API.entry(uri) }

        if eid
          file = self.fname(eid)
          return Bookmark.read_json(file, &retrieve)
        else
          res = retrieve.call
          Bookmark.save(self.fname(res['eid']), res.to_json) if res['eid']
          return res
        end
      end

      def initialize(args)
        uri = args[:uri]
        eid = args[:eid]
        @entry = self.class.cached_fetch(uri, eid)
      end

      def eid() return @entry['eid']||nil end
      def uri() return @entry['url']||'' end
      def title() return @entry['title']||'' end
      def bookmarks() return @entry['bookmarks']||[] end

      def users()
        return bookmarks.map do |b|
          user = b['user']
          timestamp = Time.parse(b['timestamp']).to_i
          { 'user' => user, 'timestamp' => timestamp }
        end
      end
    end

    class User
      SMALL = 20

      def self.fname_rss(user, size)
        return File.join(App.user_dir(user), 'rss' + size.to_s)
      end

      def self.fname_partial_information(user)
        return File.join(App.user_dir(user), 'partial.information')
      end

      def self.cached_fetch(user, size=SMALL)
        file = self.fname_rss(user, size)
        return Bookmark.read_json(file) do
          rss = API.user_rss(user, size)
          { 'total' => rss[:total],
            'bookmarks' => rss[:items].map do |item|
              eid = $1 if item.about =~ /\#bookmark-(\d+)$/
              { 'eid' => eid, 'uri' => item.link, 'title' => item.title,
                'timestamp' => item.date.to_i, 'count' => item.count }
            end }
        end
      end

      def initialize(user)
        @user = user
      end

      def recent_bookmarks(size=SMALL)
        data = self.class.cached_fetch(@user, size)
        return data['bookmarks']
      end

      def total() return self.class.cached_fetch(@user)['total'] end

      def activity()
        bs = self.class.cached_fetch(@user)['bookmarks']||[]
        t = (bs.last||{})['timestamp']
        return 0 unless t

        # bookmarks / day
        return bs.size * 1.0 * 60 * 60 * 24 / (last_update.to_i - t + 1)
      end

      def partial_information()
        file = self.class.fname_partial_information(@user)
        return Bookmark.read(file){ API.partial_information(@user) }
      end

      def last_update(size=SMALL)
        return File.mtime(self.class.fname_rss(@user, size))
      end
    end
  end
end
