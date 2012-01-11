#! /usr/bin/env ruby

$:.unshift('./lib')

require 'algorithm'
require 'app'
app = App.new

print(app.header)
puts(app.json(Algorithm.description))
