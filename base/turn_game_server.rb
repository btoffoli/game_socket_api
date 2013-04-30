# encoding: UTF-8

require 'socket'

=begin
	Especificação de protocolo
 @@EVENTS = [:CONNECTED, :LU, :LUA, :PLAY, :]
	\CONNECTED - RESPOSTA QUE O CLIENTE RECEBE DO SERVIDOR 
		APÓS ESTABELECER UMA CONEXÃO C\ SUCESSO

	\LU - REQUISICAO QUE O CLIENTE FAZ P\ RECEBER A LISTA DE CLIENTES NAO OCUPADOS
	
	\LUA - REQUISICAO QUE O CLIENTE FAZ P\ RECEBER A LISTA TODOS OS CLIENTES E SEUS STATUS

	\PLAY <***PARAMETROS***> - REQUISICAO Q O CLIENTE FAZ P/ EXECUTAR UMA JOGADA

	\PING - REQUISICAO TANTO SERVIDOR OU CLIENTE P/ SERVIR DE ACK E TESTAR A CONEXAO

	\PONG - RESPOSTA DA REQUISICAO PING P/ TESTE DE CONEXAO

	\INVITE <***USUARIO(S)***> - CLIENTE FAZ REQUISICAO AO SERVIDOR P/ INFORMAR CONVITE A
		OUTRO(S) USUARIO(S)

	\CONNECTED CANAL - RESPOSTA DO SERVIDOR AO CLIENTE 
		EM CASO DE SUCESSO NA REQUISICAO DE CONVITE, INFORMAR CANAL C/ USUARIOS 
		QUE ACEITARÃO O CONVITE
	
	\NOT_CONNECTED CANAL - RESPOSTA DO SERVIDOR AO CLIENTE INFORMANDO O NAO SUCESSO NA 
		ABERTURA DO CANAL
	

	Falta pensar numa forma de ter um listener(s) do eventos gerenciados 
	pelo servidor. Ex. Encerramento de partida, Fechamento de canal, 
	Desconexão de um dado usuário.
	Isso p/ evitar muita dependencia(referencia cruzada) entre as classes


	
=end



class TurnGameServer

  attr_reader :game_manager

  def initialize *args
    @game_manager = GameManager.new '|', ','

    @usuarios = []
    #@canais = []
    # @executando = false
    # Aguardando no terminal
    @thread_server = nil

  end

  def iniciar(porta)
    @thread_server = Thread.start do
      begin
        # @executando = true
        puts 'Iniciando servidor...'
        dts = TCPServer.new('0.0.0.0', porta)
        loop do
          Thread.new(dts.accept) do |s|
            _u = nil

            puts "s.class #{s.class} " #s.respond_to?(close) = #{s.respond_to 'close'}"


            begin
              tipo_rede, porta, domain, ip = s.addr

              _u = Usuario.new(ip: ip, porta: porta, socket: s)

              puts "cliente conectado: #{ip} - #{porta}"

              @usuarios << _u
              @game_manager.usuarios << _u

              puts "@usuarios = #{@usuarios}"

              s.puts "CONECTED|{id: \"#{_u.id}\"}"

              # Cuida do recebimento de mensagens
              # Thread.start(daemon: true) {
              while _line = s.gets # Read lines from socket
                puts "recebendo de #{s}: #{_line} \n" # and print them
                #reseta a hora da ultima conexao
                _u.ultima_conexao = Time.now
                @game_manager.processar_mensagem(_u, _line)
              end
                # }

            rescue Exception => e
              puts "#{e}\n"
              puts "Ocorreu um erro com o cliente"
            ensure
              puts 'Fechando conexao'
              fechar_conexao _u if _u
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
    @usuarios.each{ |u| fechar_conexao u}
    @usuarios.clear
  end

  def print_usuarios
    puts "Usuarios conectados: #{@usuarios}"
  end

  def checar_conexoes
    Thread.start do
      while true do
        _usuarios_problema = @usuarios
        .find_all { |u|
          Time.now - u.ultima_conexao > 300
        } #segundos
        puts "Usuarios #{_usuarios_problema} estao com problema testando...."
        _usuarios_problema.each do |u|
          puts "checando usuario #{u}"
          Thread.start do |th|
            begin
              _sockect = u.socket
              _sockect.send('ping')
              _retorno = nil
              Timeout
              .timeout { _retorno = _sockect.received(4) }

              unless _retorno
                fechar_conexao u
              end


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
    @usuarios.delete(usuario)
    puts "fechada a conexao do usuario #{usuario}"
    @game_manager.remover_usuario usuario
    usuario.socket.close unless usuario.socket.closed?
  end


end



