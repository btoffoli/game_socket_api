# encoding: UTF-8

class Partida
  attr_accessor :usuario_corrente, :primeiro_usuario, :usuarios, :positions

  def initilize *args
    super
    @usuario_corrente = @primeiro_usuario = args[:primeiro_usuario]
    @usuarios = args[:usuarios]
    @positions = []
    3.times { @positions << [] }
  end

  def proximo_usuario
    _pos = usuarios.index usuario_corrente
    if _pos == usuarios.size - 1
      @usuario_corrente = @primeiro_usuario
    else
      @usuario_corrente = usuarios[_pos]
    end
  end

  def play usuario, posicao

    #posicao => {x: i, y: j}

    return :USUARIO_INVALIDO if usuario != @usuario_corrente

    return :POSICAO_OCUPADA if @positions[posicao[:x]][posicao[:y]]

    #grava a posicao jogada pelo usuario
    @positions[posicao[:x]][posicao[:y]] = usuario

    #checando linhas
    #return :GANHADOR if ver_se_o_mesmo(@positions[0][0], @positions[0][1], @positions[0][2])
    #return :GANHADOR if ver_se_o_mesmo(@positions[1][0], @positions[1][1], @positions[1][2])
    #return :GANHADOR if ver_se_o_mesmo(@positions[2][0], @positions[2][1], @positions[2][2])
    #
    ##checando colunas
    #return :GANHADOR if ver_se_o_mesmo(@positions[0][0], @positions[1][0], @positions[2][0])
    #return :GANHADOR if ver_se_o_mesmo(@positions[0][1], @positions[1][1], @positions[2][1])
    #return :GANHADOR if ver_se_o_mesmo(@positions[0][2], @positions[1][2], @positions[2][2])
    #
    ##verificando posicoes diagonais
    #return :GANHADOR if ver_se_o_mesmo(@positions[0][0], @positions[1][1], @positions[2][2])
    #return :GANHADOR if ver_se_o_mesmo(@positions[0][2], @positions[1][1], @positions[2][0])


    #troca o corrente
    proximo_usuario

    return :PROXIMO

  end

  def ver_se_o_mesmo objeto1, objeto2, objeto3

    _resp = objeto1 == objeto2

    if _resp && objeto1 == objeto3
      return true
    else
      return false
    end

  end



  def encerrar_partida
    @finalizacao = Time.now
  end

  def sair usuario
    #usuario.
  end
end
