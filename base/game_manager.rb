# encoding: UTF-8

class GameManager

  attr_reader :usuarios, :convites, :canais, :partidas, :chars_separador_comando, :chars_separador_parametros


  def initialize char_separador_comando, char_separador_parametros

    @chars_separador_comando = char_separador_comando
    @chars_separador_parametros = char_separador_parametros
    @usuarios = []
    @convites = []
    @canais = []
    @partidas = []

  end

  def processar_mensagem usuario, mensagem

    mensagem = mensagem.gsub('\n', '')

    _comando, _parametros = mensagem.split(chars_separador_comando)


    _parametros = eval(_parametros)

    _comando_symbol = _comando.to_sym

    puts "chamando processar_mensagem usuario=#{usuario}, mensagem=#{mensagem}"

    @usuarios << usuario unless @usuarios.index usuario

    #informar nome
    if _comando_symbol == :SET_USER_INFO

      _nick = _parametros[:nick]
      _last_id = _parametros[:_last_id]

      enviar_mensagem(usuario, 'SET_USER_INFO|{STATUS:"ERROR"}') unless _nick

      usuario.nick = _nick
      usuario.last_id = _last_id
      enviar_mensagem(usuario, 'SET_USER_INFO|{STATUS: "OK"}') unless usuario.nick

      #listar usuarios
    elsif _comando_symbol == :LU

      #formata a lista de usuários p/ ser enviada p/ o usuário
      _usuarios = self.listar_usuarios_conectados.collect do |u|
        [id: u[:id],  nick: u[:nick]]
      end

      enviar_mensagem(usuario, "LU|{STATUS: \"OK\", usuarios: #{_usuarios}")

      #convidar alguem
    elsif _comando_symbol == :INVITE
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

    elsif _comando_symbol == :INVITED_DENNIED
      _str_convite_negado = mensagem.split('|')[1].strip
      _convite = @convites.find { |conv| conv.to_s == _str_convite_negado }
      if (_convite)
        _usuario_que_convidou = _convite.usuario_que_convidou
        enviar_mensagem(_usuario_que_convidou, "INVITED_DENNIED#{chars_separador_comando}#{_convite}")
      end #igonorar caso o convite nem exista no servidor

    elsif _comando_symbol == :INVITED_ACCEPT
      _str_convite_aceito = mensagem.split('|')[1].strip
      _convite = @convites.find { |conv| conv.to_s == _str_convite_aceito }
      if (_convite)
        _usuario_que_convidou = _convite.usuario_que_convidou
        _usuario_convidado = _convite.usuario_convidado
        _canal = Canal.new [_usuario_que_convidou, _usuario_convidado]
        @canais << _canal
        enviar_mensagem(_usuario_que_convidou, "INVITED_ACCEPT#{@chars_separador_comando}#{_canal}")
        enviar_mensagem(_usuario_convidado, "INVITED_ACCEPT#{@chars_separador_comando}#{_canal}")
        _convite.finalizacao = Time.now
        #por enquanto estou removendo o convite
        @convites.delete(_convite)

      end

    elsif _comando_symbol == :PLAY
      #obter o canal do parametro ou do servidor
      #obter a posicao

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


  def jogar usuario, parametros
    _str_canal = parametros.split(    )

    _canal = @canais.find do |canal|
      canal == parametros
    end
  end

  def listar_usuarios_conectados
    @usuarios.find_all do |u|
      u[:status] == Usuario
    end
  end


end
