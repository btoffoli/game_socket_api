require 'socket'


class Usuario
	attr_reader :ip, :pid, :nome, :socket, :time_without_connection

	def initialize args
		@time_without_connection = Time.now
	    args.each do |k,v|
	      instance_variable_set("@#{k}", v) unless v.nil?
	    end
  	end

  	def close_connection
  		@socket.close
  	end

	def to_s
		"<*** #{@ip} - #{@pid} - #{@socket} - #{@time_without_connection} ***>"
	end

end


class TurnGameServer

	def initialize *args
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
						_u = nil

						puts "s.class #{s.class} " #s.respond_to?(close) = #{s.respond_to 'close'}"


					   	begin
					   		tipo_rede, porta, domain, ip = s.addr

					   		_u = Usuario.new(ip: ip, porta: porta, socket: s)

					   		puts "cliente conectado: #{ip} - #{porta}"

					   		@usuarios << _u

					   		puts "@usuarios = #{@usuarios}"
					   		
					   		s.puts "@usuarios = #{@usuarios}"

					   		# Cuida do recebimento de mensagens							
					   		# Thread.start(daemon: true) {
				   			while line = s.gets # Read lines from socket
						  		puts "recebendo de #{s}: #{line} \n"         # and print them
							end							
					   		# }
											   		
					   	rescue Exception => e
					   		puts "Ocorreu um erro com o cliente"
					   	ensure
					   		puts 'Fechando conexao'
					   		fechar_conexao _u if u 
					   		# s.close
					   		# @usuarios -= [_u]
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

		self.checar_conexoes
	end	

	def parar
		if @thread_server && @thread_server.alive?
			Thread.kill(@thread_server)
		end
	end

	def limpar
		@usuarios.clear
	end

	def print_usuarios
		puts "Usuarios conectados: #{@usuarios}"
	end

	def checar_conexoes
		Thread.start do 
			while true do
				_usuarios_problema = @usuarios
				.find_all{|u| Time.now - u.time_without_connection > 30} #segundos
				puts "Usuarios #{_usuarios_problema} estao com problema testando...."
				_usuarios_problema.each do |u|
					puts "checando usuario #{u}"
					Thread.start do |th|
						begin
							_sockect = u.socket
							_sockect.send('ping')
							_retorno = nil
							Timeout
							.timeout{ _retorno = _sockect.received(4) }

							# unless _retorno 
								fechar_conexao u
							# end
							

						rescue Exception => e 
							fechar_conexao u
						end

					end
				end
				sleep 1
			end
		end
	end


	def fechar_conexao usuario
		puts "fechando conexao do usuario #{usuario}"
		usuario.close_connection
		@usuarios -= [usuario]
		puts "fechada a conexao do usuario #{usuario}"
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
