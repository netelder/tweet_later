# module Sidekiq
#   module ExceptionHandler
#     def handle_exception(ex, msg)
#       Sidekiq.logger.warn msg
#       Sidekiq.logger.warn ex
#       # Sidekiq.logger.warn ex.backtrace.join("\n")
#       # return ex to main program somehow....
#     end
#   end
# end


class TweetWorker 
  include Sidekiq::Worker
  attr_reader :tweet
  sidekiq_options :retry => 5

  def perform(tweet_id)
    @tweet = Tweet.find(tweet_id)
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
