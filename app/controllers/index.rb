get '/' do
  #adding comment
  erb :index
end

post '/tweeting' do
  content_type :json
  sent = "true"
  begin
    tweet = Tweet.create(status: params[:status], user: current_user)
    # worker = TweetWorker.perform_at(10.seconds.from_now, tweet.id)
    worker = TweetWorker.perform_async(tweet.id)
    tweet.jid = worker
    tweet.save
  rescue
    sent = "false"
  end
  [tweet.jid, sent].to_json
end

get '/status/:job_id' do
  content_type :json
  if Tweet.find_by_jid(params[:job_id]).failed?
    "duplicate".to_json
  else
    job_is_complete(params[:job_id]).to_json
  end
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
  @user = User.find_or_create_by_username(username: @access_token.params[:screen_name])
  @user.update_attributes( oauth_token: @access_token.params[:oauth_token], oauth_secret: @access_token.params[:oauth_token_secret])
  session[:user_id] = @user.id
  redirect '/'
end
