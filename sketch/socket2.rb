require 'socket'
require 'logger'
require 'fileutils'

logger = Logger.new(STDOUT)
FILE = '/tmp/socket_test'

pid = fork do
  sleep(1)
  (0..9).each do |i|
    logger.info("open (#{i})")
    s = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
    sockaddr = [ Socket::AF_UNIX, FILE ].pack('S!a108')
    s.connect_nonblock(sockaddr)
    logger.info("write")
    s.write(i.to_s)
    logger.info('write finished')
    s.close
  end
end

begin
  UNIXServer.open(FILE) do |serv|
    logger.info('wait for child process')
    Process.waitpid(pid)
    logger.info('child process finished')

    (1..10).each do |i|
      logger.info("wait for connection \##{i}")
      s = serv.accept
      logger.info('connection begin')

      data = s.read
      logger.info("receive data '#{data}'")
      s.close
      logger.info('connection end')
    end
  end
ensure
  FileUtils.rm(FILE)
end
