class TweetWorker 
  include Sidekiq::Worker

  def perform(tweet_id)
    tweet = Tweet.find(tweet_id)
    user = tweet.user
    new_user = authorize_for_tweeting(user)
    new_user.update(tweet.status)
  end 

  def authorize_for_tweeting(user)

    new_user = Twitter::Client.new(
     :oauth_token => user.oauth_token,
     :oauth_token_secret => user.oauth_secret
    )
    new_user
  end



end
