get '/' do
  #adding comment
  erb :index
end

post '/tweeting' do
  content_type :json
  sent = "true"
  puts "----------------------"
  p params
  post_time = (Chronic.parse(params[:date]) - Time.now).to_f
  begin
    tweet = Tweet.create(status: params[:status], user: current_user)
    # worker = TweetWorker.perform_at(10.seconds.from_now, tweet.id)
    if post_time < 20
      worker = TweetWorker.perform_async(tweet.id)
    else
      worker = TweetWorker.perform_in(post_time, tweet.id)
      tweet.scheduled = Time.at(Time.now + post_time)
    end
    tweet.jid = worker
    tweet.save
  rescue
    sent = "false"
  end
  [tweet.jid, sent, Time.at(Time.now + post_time)].to_json
end

get '/status/:job_id' do
  content_type :json
  tweet = Tweet.find_by_jid(params[:job_id])
  if tweet.failed?
    "duplicate".to_json
  elsif !tweet.scheduled.nil?
    tweet.scheduled.to_json
  else
    job_is_complete(params[:job_id]).to_json
  end
end

get '/tweets/future' do
  @tweets = Tweet.all(:conditions => ["scheduled >= ? AND user_id = ?", Time.now, current_user.id])
  erb :alltweets
end

get '/tweets/delete/:id' do
  if Tweet.exists?(params[:id]) && current_user.id == Tweet.find(params[:id]).user_id
    Tweet.destroy(params[:id])
  end
  redirect '/tweets/future'
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
