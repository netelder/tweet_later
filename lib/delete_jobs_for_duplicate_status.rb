module TweetLater
  class Sidekiq
    def call(worker, msg, queue)
      begin
        yield
      rescue Twitter::Error::Forbidden
        p worker.tweet.mark_failed!
      end
    end
  end
end

::Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add ::TweetLater::Sidekiq
  end
end
