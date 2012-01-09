#! /usr/bin/env ruby
require 'net/http'
require 'uri'
require 'rss'

wait = 0.5
num = 100

if %w'-h --help'.any?{|x| $*.delete(x)} || $*.size < 1
  print <<"EOM"
Usage: #{$0} [--wait=<seconds>] <user> [<num>]
  Retrieve URLs of bookmarks of <user>.
Options:
  --wait=<seconds>    Sleep before subsequent queries (default: #{wait}).
  <num>               The number of entries to be retrieved (default: #{num}).
EOM
  exit
end

$*.reject!{|x|x=~/^--wait=(.*)$/ && wait=$1.to_f}
user = $*.shift
num = ($*.shift || num).to_i
i=0

url = URI.parse('http://b.hatena.ne.jp/'+user+'/rss')
http = Net::HTTP.start(url.host, url.port)

loop do
  res = http.request(Net::HTTP::Get.new(url.path+"?of=#{i}"))
  rss = RSS::Parser.parse(res.body)
  entries = rss.items.map(&:link)
  entries = entries[0...num] if entries.size > num
  puts(entries)
  i += entries.size
  num -= entries.size

  break if num <= 0
  sleep(wait)
end
