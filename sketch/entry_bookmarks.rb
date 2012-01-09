#! /usr/bin/env ruby
require 'net/http'
require 'uri'
require 'time'

require 'rubygems'
require 'json'

wait = 0.5

if %w'-h --help'.any?{|x| $*.delete(x)}
  print <<"EOM"
Usage: #{$0} [--wait=<seconds>] [<URL>]
  Retrieve users who has bookmarked <URL>.
Options:
  --wait=<seconds>    Sleep before subsequent queries (default: #{wait}).
  <URL>               If none, URLs are read from each line of standard input.
EOM
  exit
end

$*.reject!{|x|x=~/^--wait=(.*)$/ && wait=$1.to_f}

urls = $*.size >= 1 ? [ $*.shift ] : ARGF.read.to_a

urls.each_with_index do |entry,i|
  url = URI.parse('http://b.hatena.ne.jp/entry/jsonlite/?url-')
  http = Net::HTTP.start(url.host, url.port)
  entry = URI::encode(URI::decode(entry.strip))
  res = http.request(Net::HTTP::Get.new(url.path+entry))
  if res.code.to_i >= 200 && res.code.to_i < 300
    begin
      e = JSON.parse(res.body)
      data = [ e['eid'] ] + (e['bookmarks']||[]).reverse.map do |b|
        b['user']+':'+Time.parse(b['timestamp']).to_i.to_s
      end
      puts(data.join("\t"))
    rescue => e
      $stderr.puts(entry)
      $stderr.puts(e.backtrace, e)
    end
  end
  sleep(wait) unless i == urls.size-1
end
