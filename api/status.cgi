#! /usr/bin/env ruby

$:.unshift('./lib')

STATUS = {
  400 => '400 Bad Request'
}

require 'app'
app = App.new

app.error_exit(STATUS[400]) unless app.user
app.error_exit(STATUS[400]) unless app.algorithm

app.status do |st,val|
  case st
  when :done
    print(app.header)
    puts(app.json(:status => :done))
  when :running
    print(app.header)
    puts(app.json(:status => :running, :progress => val))
  when :queued
    print(app.header)
    puts(app.json(:status => :queued))
  when :ready
    print(app.header)
    puts(app.json(:status => :ready))
  end
end
