#!/usr/bin/env ruby

# Webserver which tells collectors which blocks to read

require 'socket'

path = ENV['DB_PATH'] || '/data'

begin
  $last_block_index = Dir["#{path}/data/*"].sort.first.split('/').last.split('.').first.to_i
ensure
  $last_block_index ||= 511422
end

server = TCPServer.new 5678
while session = server.accept
  request = session.gets
  puts request

  session.print "HTTP/1.1 200\r\n"
  session.print "Content-Type: application/json\r\n"
  session.print "\r\n"
  session.print "{\"last_block_index\": #{$last_block_index}}"
  $last_block_index -= 1

  session.close
end
