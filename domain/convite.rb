# encoding: UTF-8

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