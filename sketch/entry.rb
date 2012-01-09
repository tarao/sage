$:.unshift(File.join(File.dirname($0), '..', 'lib'))
require 'hatena/bookmark'

uris =
  [
   'http://en.wikibooks.org/wiki/More_C%2B%2B_Idioms',
   'http://d.hatena.ne.jp/keyword/%A4%B8%A4%E3%A4%CA%A4%AB%A4%C3%A4%BF%A4%CE%A4%AB%A5%BB%A5%CB%A5%E7%A1%BC%A5%EB',
   'http://ja.wikipedia.org/wiki/%E7%84%A1%E9%99%90%E3%81%AE%E7%8C%BF%E5%AE%9A%E7%90%86',
   'http://git.linux-nfs.org/?p=bhalevy/git-tools.git;a=blob_plain;f=git-rebase-tree;hb=HEAD',
   'http://webcache.googleusercontent.com/search?q=cache:bjL0PUSyc5MJ:wikiwiki.jp/disklessfun/%3Fdisklessfc+nfsroot+debian&cd=44&hl=ja&ct=clnk&gl=jp&source=www.google.co.jp',
  ]
uris.each do |uri|
  puts(uri)
  entry = Hatena::Bookmark::Entry.new(:uri => uri)
  entry.users.each do |u|
    puts("#{u['user']}:#{u['timestamp']}")
  end
end
