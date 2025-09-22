require 'json'
require 'pp'
require_relative 'config/environment'

require 'socket'

server = TCPServer.new 4000
loop do
  Thread.start(server.accept) do |client|
    # client.puts "Recibo la data"
    while line = client.gets
      puts line # Prints whatever the client enters on the server's output
      # ActionCable.server.broadcast "publicas_deporte_channel",data: {"tipo" => "data_lsport", "msg" => line}
    end
    client.close
  end
end
