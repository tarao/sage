require 'socket'
require 'logger'
require 'fileutils'

logger = Logger.new(STDOUT)
FILE = '/tmp/socket_test'

fork do
  sleep(3)
  logger.info('open (a)')
  UNIXSocket.open(FILE){|s| s.write('a')}
end

fork do
  sleep(4)
  logger.info('open (b)')
  UNIXSocket.open(FILE){|s| s.write('b')}
end

fork do
  sleep(5)
  logger.info('open (c)')
  UNIXSocket.open(FILE){|s| s.write('c')}
  logger.info('open (d)')
  UNIXSocket.open(FILE){|s| s.write('d')}
  logger.info('open (e)')
  UNIXSocket.open(FILE){|s| s.write('e')}
end

fork do
  sleep(5)
  (0..9).each do |i|
    logger.info("open (#{i})")
    UNIXSocket.open(FILE){|s| s.write(i.to_s)}
  end
end

UNIXServer.open(FILE) do |serv|
  (1..15).each do |i|
    logger.info("wait for connection \##{i}")
    s = serv.accept
    logger.info('connection begin')

    data = s.read
    logger.info("receive data '#{data}'")
    s.close
    logger.info('connection end')
  end
end

FileUtils.rm(FILE)
