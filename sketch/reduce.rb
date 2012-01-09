#! /usr/bin/env ruby

if %w'-h --help'.any?{|x| $*.delete(x)}
  print <<"EOM"
Usage: #{$0}
EOM
  exit
end

users = {}
ARGF.each do |line|
  data = line.strip.split("\t")
  eid = data.shift

  data.map{|u| u.split(':')}.each do |u,s|
    users[u] = users[u] || { :score => 0, :entries => [] }
    users[u][:score] += s.to_f
    users[u][:entries] << eid
  end
end

# users.sort{|a,b| b[1][:score] <=> a[1][:score]}.each do |u, x|
#   puts([ u, x[:score].to_s, x[:entries].join(',') ].join("\t") )
# end

users.sort{|a,b| b[1][:entries].size <=> a[1][:entries].size}.each do |u,x|
  puts([ u, x[:entries].size, x[:score].to_s, x[:entries].join(',') ].join("\t") )
end
