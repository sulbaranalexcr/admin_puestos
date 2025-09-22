class BasesUrlsController < ApplicationController
  def index
    @urls = if BaseUrl.all.present? 
              BaseUrl.first
            else
              BaseUrl.new
            end

  end

  def show

  end

  def update
    @BasesUrl = if BaseUrl.last.present?
                  BaseUrl.update(gticket: params[:gticket], pendientes: params[:pendientes])
                else
                  BaseUrl.create(gticket: params[:gticket], pendientes: params[:pendientes])
                end
    redirect_to '/bases_urls'
  end
end
