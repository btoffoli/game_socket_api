require 'socket'  

include Socket::Constants

#Bombando string
class String
  def trim!(chars)
    rtrim!(chars)
    ltrim!(chars)
  end

  def rtrim!(chars)
    gsub!(/(#{trim_prepare(chars)})+$/, '')
  end

  def ltrim!(chars)
    gsub!(/^(#{trim_prepare(chars)})+/, '')
  end

  def trim(chars)
    dup.rtrim(chars).ltrim(chars)
  end

  def rtrim(chars)
    dup.rtrim!(chars)
  end

  def ltrim(chars)
    dup.ltrim!(chars)
  end

  private
  def trim_prepare(chars)
    chars = chars.split("").collect { |char| Regexp.escape(char) }
    chars.join('|')
  end
end

#s = TCPSocket.open 'localhost', 2000
s = TCPSocket.open '192.34.57.47', 2000

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
  		s.puts comando.strip

  		s.flush
	end
end

t_recebimento.join

t_envio.join




s.close    