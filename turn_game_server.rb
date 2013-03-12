# encoding: UTF-8

require 'socket'

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

class ObjetoBase
  attr_reader :id, :criacao
  attr_accessor :finalizacao


  def initialize *args
    require 'securerandom'
    @id = SecureRandom.uuid
    @criacao = Time.now
  end

  def to_s
    "<class:#{self.class} id:#{@id} - criacao:#{@criacao}>"
  end

end


class UsuarioEvent
  attr_accessor :usuario, :type_event, :more_params

  def initialize usuario, type_event, more_params
    @usuario = usuario
    @type_event = type_event
    @more_params = more_params
  end


end


class UsuarioEventsListener < ObjetoBase
  #@@EVENTOS = [:CONNECTED, :DISCONNECTED, :INVITED, :INVITED_ACCEPT, :INVITED_DENIED]

  #  Talvez seja melhor implementar um has_user p/ quem herdar implementar e saber se o mesmo esta interessado em eventos
  # daquele usuario

  def call_event usuario_event
    begin

      self.send(usuario_event[:type_event].to_s.downcase, usuario_event[:usuario], usuario_event[:more_params])

    rescue NoMethodError => no_meth_exp
      puts "Sem metodo p/ o evento em questão."

    rescue ArgumentError => arg_error
      puts "Metodo com número de argumentos errados ou mal implementado."
    ensure
      puts "Termino de call_event."
    end
  end


  def connected usuario, parametros
    puts "usuario #{usuario} conectado c/ parametros #{parametros}"
  end


  def disconnected usuario, parametros
    puts "usuario #{usuario} disconectado c/ parametros #{parametros}"
  end

  def invited usuario, parametros
    puts "usuario #{usuario} convidado c/ parametros #{parametros}"
  end


  def invited_accept usuario, parametros
    puts "usuario #{usuario} conectado c/ parametros #{parametros}"
  end


  def invited_denied usuario, parametros
    puts "usuario #{usuario} conectado c/ parametros #{parametros}"
  end


end


class Convite < ObjetoBase

  attr_accessor :usuario_que_convidou, :usuario_convidado, :status

  # Estados do convite CRIADO ENVIO, AGUARDANDO, ACEITE e NEGADO e QUEDA_CONEXAO
  # sendo que ENVIO e AGUARDANDO o

  def initialize usuario_que_convidou, usuario_convidado
    #require 'set'
    super


    @usuario_que_convidou = usuario_que_convidou
    @usuario_convidado = usuario_convidado
    @status = :CRIADO

  end

  #verificar se a melhor forma seria apenas marcar o estado do convite depois o p/ o game_manager resolver c/ mensagens com respectivos usuários
  # ou já enviar mensagem de aviso ao usuaŕios através do socket

  def disconnected usuario, parametros
    @finalizacao = Time.now
    @status = :QUEDA_CONEXAO

    # Se for o usuario que criou o convite
    @usuario_convidado.socket.send("CONVITE_CANCELADO | #{@usuario_que_convidou} | MOTIVO: QUEDA_CONEXAO") if @usuario_que_convidou == usuario

    # Se for o usuario que recebeu o  o convite
    @usuario_que_convidou.socket.send("CONVITE_CANCELADO | #{@usuario_convidado} | MOTIVO: QUEDA_CONEXAO") if @usuario_convidado == usuario

    nil

  end

  def invited_accept
    @finalizacao = Time.now
    @status = :ACEITE

    @canal = Canal.new(usuario1: @usuario_que_convidou, usuario2: @usuario_convidado)

    # Se for o usuario que criou o convite
    @usuario_que_convidou.socket.send("CONVITE_ACEITO | USUARIO: #{@usuario_que_convidou} | CANAL: #{_canal}")


  end


end


class Usuario < ObjetoBase

  attr_accessor :ip, :pid, :nome, :socket, :time_without_connection, :partida


  #será assumido como chave do usuario o @socket.to_s


  def initialize args
    super
    @ultima_conexao = Time.now
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end


  def to_s
    "<id:#{@id} - nome:#{@nome} - ip:#{@ip} - socket:#{@socket} - ultima_conexao:#{@ultima_conexao}>"
  end

end

class Partida < UsuarioEventsListener
  attr_accessor :usuario_corrente, :primeiro_usuario, :usuarios

  def initilize args
    super
    @usuario_corrente = @primeiro_usuario = args[:primeiro_usuario]
    @usuarios = args[:usuarios]
  end

  def proximo_usuario
    _pos = usuarios.index usuario_corrente
    if _pos == usuarios.size - 1
      @usuario_corrente = @primeiro_usuario
    else
      @usuario_corrente = usuarios[_pos]
    end
  end

  def encerrar_partida
    @finalizacao = Time.now
  end

  def sair usuario
    #usuario.
  end
end


class Canal < ObjetoBase
  attr_reader :usuarios, :last_activity

  def initialize usuarios
    super
    @last_activity = Time.now
    @usuarios = usuarios


    #preenche todos os usuarios
    #args.each do |k, v|
    #  @usuarios << v if k.to_s =~ /^?(usuario)/ and not v.nil?
    #end

    # .find_all {|k,v| k.to_s =~ /^?(usuario)/ and not v.nil?}


  end

  def fechar_canal
    # Notifica os usuarios
    usuarios.each do |u|
      u.send("\canal")
    end
    # Marca o canal como fechado
    @finalizacao = Time.now

  end

end


class GameManager

  attr_reader :usuarios, :convites, :canais, :partidas


  def initialize
    @usuarios = []
    @convites = []
    @canais = []
    @partidas = []
  end

  def processar_mensagem usuario, mensagem

    mensagem = mensagem.gsub('\n', '')

    puts "chamando processar_mensagem usuario=#{usuario}, mensagem=#{mensagem}"

    @usuarios << usuario unless @usuarios.index usuario

    #informar nome
    if mensagem.index 'INFORMAR_NOME|'

      _nome = mensagem.split('|')[1]
      puts "nome=#{_nome}"
      usuario.nome = _nome
      enviar_mensagem(usuario, 'INFORMAR_NOME_NOVAMENTE|') unless usuario.nome

      #listar usuarios
    elsif mensagem.index 'LU|'

      enviar_mensagem(usuario, "usuarios|#{@usuarios.to_s}")

      #convidar alguem
    elsif mensagem.index 'INVITE|'

      _str_convidado = (mensagem.split('|')[1]).strip
      #usa como chave p/ buscar o usuário o socket.to_s
      _convidado = @usuarios.find { |u| u.to_s == _str_convidado }

      if _convidado
        _convite = Convite.new(usuario, _convidado)
        @convites << _convite
        enviar_mensagem(_convidado, "INVITED|#{_convite}")
      else
        enviar_mensagem(usuario, "INVITED_CANCELED|USUARIO_INVALIDO")
      end

    elsif mensagem.index 'INVITED_DENNIED|'
      _str_convite_negado = mensagem.split('|')[1].strip
      _convite = @convites.find { |conv| conv.to_s == _str_convite_negado }
      if (_convite)
        _usuario_que_convidou = _convite.usuario_que_convidou
        enviar_mensagem(_usuario_que_convidou, "INVITED_DENNIED|#{_convite}")
      end #igonorar caso o convite nem exista no servidor

    elsif mensagem.index 'INVITED_ACCEPT|'
      _str_convite_aceito = mensagem.split('|')[1].strip
      _convite = @convites.find { |conv| conv.to_s == _str_convite_aceito }
      if (_convite)
        _usuario_que_convidou = _convite.usuario_que_convidou
        _usuario_convidado = _convite.usuario_convidado
        _canal = Canal.new [_usuario_que_convidou, _usuario_convidado]
        @canais << _canal
        enviar_mensagem(_usuario_que_convidou, "INVITED_ACCEPT|#{_canal}")
        enviar_mensagem(_usuario_convidado, "INVITED_ACCEPT|#{_canal}")
        _convite.finalizacao = Time.now
        #por enquanto estou removendo o convite
        @convites.delete(_convite)

      end
    else
      puts "mensagem #{mensagem} não reconhecida...."


    end
  end


  def enviar_mensagem usuario, mensagem
    begin
      usuario.socket.puts(mensagem.strip)
    rescue Exception => exp

      puts "Erro ao enviar mensagem #{mensagem} ao usuario #{usuario}, exp = #{exp}"
    end
  end


  def remover_usuario usuario
    @usuarios.delete(usuario)

    #remove convites dos usuários
    _convites_a_serem_removidos = []
    @convites.each do |conv|
      #manda mensagem de cancelamento de convite ao outro usuario
      enviar_mensagem(conv.usuario_convidado, "INVITED_CANCELED|#{conv}") if conv.usuario_que_convidou == usuario
      enviar_mensagem(conv.usuario_que_convidou, "INVITED_CANCELED|#{conv}") if conv.usuario_convidado == usuario
      _convites_a_serem_removidos << conv
    end
    _convites_a_serem_removidos.each { |conv| @convites.delete conv }

    #remove canais dos usuários
    _canais_a_serem_removidos = []
    @canais.each { |canal| _canais_a_serem_removidos << canal  }
    _canais_a_serem_removidos.each do |canal|
      @canais.delete canal
      canal.usuarios.each do |usu|
        enviar_mensagem(usu, "CHANEL_CANCELED|#{canal}")
      end
    end

    puts "@convites=#{@convites}\n@canais=#{@canais}"

  end


  def print_status
    puts "Usuarios conectados: #{@usuarios}"
    puts "Convitess: #{@convites}"
    puts "Canais: #{@canais}"
  end


end


class TurnGameServer

  attr_reader :game_manager

  def initialize *args
    @game_manager = GameManager.new

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
              @game_manager.usuarios << _u

              puts "@usuarios = #{@usuarios}"

              s.puts "@usuarios = #{@usuarios}"

              # Cuida do recebimento de mensagens
              # Thread.start(daemon: true) {
              while _line = s.gets # Read lines from socket
                puts "recebendo de #{s}: #{_line} \n" # and print them
                @game_manager.processar_mensagem(_u, _line)
              end
                # }

            rescue Exception => e
              puts "#{e}"
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
        .find_all { |u| Time.now - u.time_without_connection > 30 } #segundos
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
    @usuarios.delete(usuario)
    puts "fechada a conexao do usuario #{usuario}"
    @game_manager.remover_usuario usuario
  end


end


porta = 0
while porta < 1024 do
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
      when 'status'
        server.game_manager.print_status
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
