require 'socket'


class TurnGameServer

	def initialize(*args)
		@usuarios = []		
		# @executando = false
		# Aguardando no terminal
		@thread_server = nil

	end

	def iniciar(porta)		
		@thread_server = Thread.start do
			begin						
				# @executando = true
				puts 'Iniciando servidor...'
				dts = TCPServer.new('localhost', porta)  
				loop do  
				  Thread.new(dts.accept) do |s|
				  	# puts "s.class = #{s.class}"
				   #  puts(s, " is accepted\n")  
				   #  100.times {
				   #  	s.write(Time.now)  
				   #  	s.write('teste')    
				   #  }
				   #  s.flush()
				   #  p(s, " is gone\n")
				   #  puts s.recv(10000, 0.5)  
				   #  s.close  
				   begin

				   		tipo_rede, porta, domain, ip = s.addr
				   		puts "cliente conectado: #{ip}"

				   		@usuarios << s

				   		puts "@usuarios = #{@usuarios}"
				   		
				   		s.puts "@usuarios = #{@usuarios}"

				   		# Cuida do recebimento de mensagens							
				   		# Thread.start(daemon: true) {
				   			while line = s.gets # Read lines from socket
						  		puts "recebendo: #{line} \n"         # and print them
							end							
				   		# }
										   		
				   rescue Exception => e
				   		puts "Ocorreu um erro com o cliente"
				   ensure
				   		puts 'Fechando conexao'
				   		s.close
				   		# @usuarios - s
				   end




				  end  
				end  
			rescue abort_on_exception => aoe	
				puts 'parando servico...'
			rescue Exception => e
				puts 'Ocorreu uma falha no servidor, encerrando...'
			end
		end

		# @thread_server.join()
	end	

	def parar()
		if @thread_server && @thread_server.alive?
			Thread.kill(@thread_server)
		end
	end

	def limpar()
		@usuarios.clear
	end

	def print_usuarios()
		puts "Usuarios conectados: #{@usuarios}"
	end
	
end



porta = 0
while porta < 1024	do
	print 'Entre com a porta do servidor: '
	porta = gets.chomp.to_i	
end

server = TurnGameServer.new

server.iniciar porta

sleep 2

comando = ''
while true do
	begin
		print 'Entre com o novo comando: '
		comando = gets.chomp

		case comando
		when 'lu'
			server.print_usuarios
		when 'clear'
			server.limpar
			# break
		when 'sair'
			 break			
			
		end
				

	rescue Exception => e
		puts e.message
	    puts e.backtrace.inspect
	end	
end
server.parar
