require 'socket'

sock = TCPSocket.open('localhost', 6500)

sock.write("<policy-file-request\/>")
while line = sock.gets   # Read lines from the socket
  puts line
end
sock.close
