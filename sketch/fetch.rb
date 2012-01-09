$:.unshift(File.join(File.dirname($0), '..', 'lib'))
require 'app/http'

uris =
  [ 'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://orezdnu.org/',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://orezdnu.org/',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://orezdnu.org/',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
    'http://test.orezdnu.org/foo.txt',
  ]

start = Time.now.to_f

uris.each do |uri|
  r = App::HTTP.fetch(uri)
  puts(uri)
  puts(r)
  puts(Time.now.to_f)
  puts
end
