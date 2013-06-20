## Extending Tweet-Later

For my 'hardest challenge yet' project, I chose to dig in to sidekiq and redis to better understand
how they work, and how they can be controlled/monitored to provide feedback to the user.

### Propagating errors from Twitter to the User

The first task was to figure out how to better process errors from Twitter.  Twitter returns errors
as http error codes, which the Twitter gem maps to various error strings.  In the case of duplicate
posts (or other unspecified posting errors), Twitter returns a 403 error, which the gem translates to
Twitter::Error::Forbidden.

In order to access this error, it's necessary to hook the exception processing within Sidekiq.  Per the
documentataion, the recommended approach is to define and register a middleware handler with Sidekiq:

```ruby
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
```

To communicate the status with the front-end javascript, a field in the Tweet database is set to 'failed'
to indicate that this post was rejected with a '403' error from Twitter.

Additional `rescue` statements can be used to handle other Twitter errors.

One of the challenges with Sidekiq is that it considers its worker queues immutable.  There are no
direct methods to select/modify a particular job.  One must iterate through a queue, and 
find a particular job before one can operate on it.  For example (from the Sidekiq doc) this
is how to delete a job with a particular jid from a queue named 'mailer':

```ruby
queue = Sidekiq::Queue.new("mailer")
queue.each do |job|
  job.delete if job.jid == 'abcdef1234567890'
end
```

For small implementations like TweetLater, this is not a serious problem.  For a large implementation 
with millions of jobs, this could well be a disaster.

## Scheduled Tweets

Sidekiq provides 'perform_in' and 'perform_at' methods to allow jobs to be scheduled for the future.  A 
simple extention to the UI allows the user to specify a future date/time for the post to occur.  Using
the Chronic gem allows a wide variety of time specifications (including strings like 'next tuesday'), making the UI
that much more friendly.



