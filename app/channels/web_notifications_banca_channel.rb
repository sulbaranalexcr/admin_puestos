class WebNotificationsBancaChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from "web_notifications_banca_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def enviar_notificacion(data)
     ActionCable.server.broadcast "web_notifications_banca_channel", { data: data }
  end


end
