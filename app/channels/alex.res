class PublicasChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from "publicas_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def enviar_notificacion(data)
     ActionCable.server.broadcast "publicas_channel",data: data
  end


end
