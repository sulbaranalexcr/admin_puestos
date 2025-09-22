class LoginController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout "login"

  def index
  end

  def create
    session.clear
    username = params[:user][:username]
  	password = params[:user][:password]

    @user = User.find_by(username: username)
    if @user && @user.authenticate(password)
      if @user.activo

          @user.update(token: SecureRandom.hex(32))
          session[:token] = @user.token
          session[:usuario_actual] = @user
    			redirect_to '/home' and return
      else
        redirect_to  '/login' , alert: 'Usuario desactivado.' and return
      end
		else
			redirect_to  '/login' , alert: 'Usuario o contrasena incorrecta*' and return
		end
  end

  def destroy
		token = session[:token]
    if token.present?
      usuario  = User.find_by token: token
			usuario.update(token: nil) if usuario.present?
			#elimminado session
			session.delete(:token)
      cookies.delete(:token)
    end
    redirect_to '/login'  and return
  end
end
