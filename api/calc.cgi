#! /usr/bin/env ruby

$:.unshift('./lib')

STATUS = {
  400 => '400 Bad Request'
}

require 'app'
require 'app/run'
app = App.new

app.error_exit(STATUS[400]) unless app.user

script = App::SCRIPT['batch_recommend_curators']
system("#{script} '#{app.user}' >/dev/null 2>&1")
code = $?.exitstatus

print(app.header)
case App::RUN_SIGNAL.invert[code]
when :start
  puts(app.json(:status => :queued))
when :already_running
  puts(app.json(:status => :locked))
when :too_many_processes
  puts(app.json(:status => :busy))
when :size_limit_exceeded
  puts(app.json(:status => :full))
else
  puts(app.json(:status => :error, :value => code))
end
