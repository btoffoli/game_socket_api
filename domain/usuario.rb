# encoding: UTF-8

class Usuario < ObjetoBase

  attr_accessor :ip, :pid, :nick, :socket, :ultima_conexao, :partida, :last_id


  #será assumido como chave do usuario o @socket.to_s

  module Usuario_Status
    enum :CONECTADO, :OCUPADO, :DESCONECTADO
  end

  def initialize args
    super
    @ultima_conexao = Time.now
    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end


end
