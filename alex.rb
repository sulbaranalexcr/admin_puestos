require 'net/http'
require 'net/smtp'
require 'uri'
require 'json'
require 'pp'
require_relative 'config/environment'
require 'rufus-scheduler'
ENV['TZ'] = 'America/Caracas'



def pase_correo(error,mensaje)
ErroresSistema.create(app: 4, app_detalle: "Reloj Deportes", error: error, detalle: mensaje, nivel: 1, reportado: false)
message = <<EOF
From: sulbaranalex@gmail.com
To: sulbaranalex@gmail.com
Subject: Error en el cron #{error}

#{error}
#{mensaje}
EOF

smtp = Net::SMTP.new 'smtp.gmail.com', 587
smtp.enable_starttls
smtp.start('gmail.com', 'unpuestosoporte@gmail.com', 'alex21ss', :login)
smtp.send_message message, 'unpuestosoporte@gmail.com', 'sulbaranalex@gmail.com','rafaeljmorales@gmail.com'
smtp.finish
end

scheduler = Rufus::Scheduler.new

# def scheduler.on_error(job, error)
#    pase_correo(error.message,error.backtrace.inspect)
# end

scheduler.cron '00 01 * * *' do
  redis = Redis.new(host: Figaro.env.REDIS_HOST, port: 6379)
  redis.del("cierre_deporte")
end




scheduler.every '10s' do
aa = ActionCable.server.broadcast "publicas_deporte_channel",data: {"tipo" => 22}
puts aa
puts "************"
end
scheduler.join
