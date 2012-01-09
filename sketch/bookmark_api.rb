$:.unshift(File.join(File.dirname($0), '..', 'lib'))
require 'hatena/bookmark'

user = Hatena::Bookmark::User.new('tarao')
puts("total: #{user.total}")
puts("activity: #{user.activity}")
user.recent_bookmarks.each do |b|
  puts("[entry: #{b['uri']} @ #{b['timestamp']}]")
  entry = Hatena::Bookmark::Entry.new(:uri => b['uri'], :eid => b['eid'])
  entry.users.each do |u|
    puts("#{u['user']}:#{u['timestamp']}")
  end
end
