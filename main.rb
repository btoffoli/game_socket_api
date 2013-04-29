# encoding: UTF-8

require 'bootstrap'

begin
  _porta = ARGV[0].to_i
rescue
  puts "Parametro inválida...."
ensure


end

while _porta < 1024 do
  print 'Entre com a porta do servidor: '
  _porta = gets.chomp.to_i
end

server = TurnGameServer.new

server.iniciar _porta

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