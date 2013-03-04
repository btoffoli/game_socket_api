require 'socket'  

include Socket::Constants

s = TCPSocket.open 'localhost', 2000

timeval = [5, 0].pack("l_2")
s.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, timeval
# s.timeout = 5
# s = Socket.new( AF_INET, SOCK_STREAM, 0 )
# sockaddr = Socket.pack_sockaddr_in( 2000, 'localhost' )
# s.bind( sockaddr )
# s.timeout -1
# Cuida do recebimento de mensagens
t_recebimento = Thread.start(daemon: true) do 
	while line = s.gets # Read lines from socket
  		puts "recebendo: #{line} \n"         # and print them
	end
end

# Cuida do envio de mensagens
t_envio = Thread.start(daemon: true) do 
	comando = ''
	while  comando != 'sair' # Read lines from socket
  		# puts "recebendo: #{line} \n"         # and print them
  		print "Entre com um comando: #{gets}" 
  		comando = gets
  		s.puts comando
  		s.flush
	end
end

t_recebimento.join

t_envio.join




s.close    