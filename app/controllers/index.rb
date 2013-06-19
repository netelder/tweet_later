get '/' do
  #adding comment
  erb :index
end

post '/tweeting' do
  content_type :json
  sent = "true"
  begin
    new_user = authorize_for_tweeting(current_user)
    new_user.update(params[:tweet])
  rescue
    sent = "false"
  end
  sent.to_json
end

get '/sign_in' do
  redirect request_token.authorize_url
end

get '/sign_out' do
  session.clear
  redirect '/'
end

get '/auth' do
  @access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
  session.delete(:request_token)
  @user = User.create(username: @access_token.params[:screen_name], oauth_token: @access_token.params[:oauth_token], oauth_secret: @access_token.params[:oauth_token_secret])
  session[:user_id] = @user.id
  redirect '/'
end
