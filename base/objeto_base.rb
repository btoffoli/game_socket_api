# encoding: UTF-8

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