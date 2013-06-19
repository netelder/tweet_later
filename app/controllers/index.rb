get '/' do
  #adding comment
  erb :index
end

post '/tweeting' do
  content_type :json
  sent = "true"
  begin
    tweet = Tweet.create(status: params[:status], user: current_user)

    TweetWorker.perform_async(tweet.id)
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
  p @access_token

  @user = User.find_or_create_by_username(username: @access_token.params[:screen_name])
  @user.update_attributes( oauth_token: @access_token.params[:oauth_token], oauth_secret: @access_token.params[:oauth_token_secret])
  session[:user_id] = @user.id
  redirect '/'
end