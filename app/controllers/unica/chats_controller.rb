module Unica
  class ChatsController < ApplicationController
    skip_before_action :verify_authenticity_token

    def chats_all
      chats = if session[:usuario_actual]["tipo"] == "ADM"
                Chat.where(delivered: false, removed: false).last(100).map { |a| { 'id' => a.id, 'message' => a.message } } #Chat.where(delivered: false, removed: false).last(100).map { |a| a.message }
              else
                Chat.where(grupo_id: session[:usuario_actual]["grupo_id"], delivered: false, removed: false).last(100).map { |a| { 'id' => a.id, 'message' => a.message } } #Chat.where(grupo_id: session[:usuario_actual]["grupo_id"], delivered: false, removed: false).last(100).map { |a| a.message }
              end
      render json: { 'chats' => chats }          
    end

    def remove_item
      chat = Chat.find(params[:id])
      chat.update(removed: true)
    end

    def send_item
      ActionCable.server.broadcast('web_notifications_banca_channel', { data: { tipo: 0, chat_id: params[:id], procesa: session[:usuario_actual]['id'] } })
      chat = Chat.find(params[:id])
      return if chat.delivered

      data_chat = chat.message
      data_chat['data']['show'] = params[:type].to_i == 1 ? true : false
      chat.update(delivered: true, for_all: params[:type].to_i == 1 ? true : false, message: data_chat, user_id: session[:usuario_actual]['id'])
      ActionCable.server.broadcast('chat_channel', data_chat) 
    end

    def en_observacion
      desde = params[:desde].to_time.beginning_of_day
      hasta = params[:hasta].to_time.end_of_day
      @chats = Chat.where("created_at >= ? AND created_at <= ?", desde, hasta).where(for_all: false, grupo_id: session[:usuario_actual]["grupo_id"]).map { |a| { 'id' => a.id, 'message' => a.message } }
      render partial: 'en_observacion' 
    end
  end
end
