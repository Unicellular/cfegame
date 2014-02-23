class SessionsController < ApplicationController
  def create
    auth_data = request.env['omniauth.auth']
    auth = Authorization.find_by( provider: auth_data['provider'], uid: auth_data['uid'] ) 
    user = auth.nil? ? User.create_with_omniauth(auth_data) : auth.user
    session[:user_id] = user.id
    if !user.email
      redirect_to edit_user_path(user), :alert => "Please enter your email address."
    else
      redirect_to root_url, :notice => "Signed in!"
    end
  end

  def destroy
    reset_session
    redirect_to root_url, :notice => "Signed out!"
  end

  def new
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end
end
