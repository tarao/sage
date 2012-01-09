#! /usr/bin/env ruby

if %w'-h --help'.any?{|x| $*.delete(x)} || $*.size < 1
  print <<"EOM"
Usage: #{$0} <user>
EOM
  exit
end

user = $*.shift

ARGF.each do |line|
  data = line.strip.split("\t")
  eid = data.shift

  users = data.map{|u| u.split(':')}.take_while{|u,t| u != user}
  i = 0
  size = users.size
  users = users.map do |u,t|
    score = 100.0 - i * (100.0/size)
    i += 1
    u+':'+score.to_s
  end

  puts(([ eid ] + users).join("\t"))
end
