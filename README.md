## Extending Tweet-Later

For my 'hardest challenge yet' project, I chose to dig in to sidekiq and redis to better understand
how they work, and how they can be controlled/monitored to provide feedback to the user.

### Propagating errors from Twitter to the User

The first task was to figure out how to better process errors from Twitter.  Twitter returns errors
as http error codes, which the Twitter gem [maps to various error strings](https://github.com/sferik/twitter/tree/master/lib/twitter/error).  In the case of duplicate
posts (or other unspecified posting errors), Twitter returns a 403 error, which the gem translates to
Twitter::Error::Forbidden.

In order to access this error, it's necessary to hook the exception processing within Sidekiq.  While monkeypatching does work (I tried it), the [recommended approach](https://github.com/bugsnag/bugsnag-ruby/blob/master/lib/bugsnag/sidekiq.rb) is to define and register a middleware
handler with Sidekiq:

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
to indicate that this post was rejected with a '403' error from Twitter.  Not, but without an explicit
"duplicate" error message from Twitter, about the best we can do.

Additional `rescue` statements can be used to handle other Twitter errors.

### Scheduled Tweets

Sidekiq provides 'perform_in' and 'perform_at' methods to allow jobs to be scheduled for the future.  A 
simple extention to the UI allows the user to specify a future date/time for the post to occur.  Using
the Chronic gem allows a wide variety of time specifications (including strings like 'next tuesday'), making the UI
that much more friendly.  Chronic can fail in odd ways, so be sure to check for a nil return value!  One more
thing for production scale use: when the argument given to Chronic resolves to a day (eg 'next tuesday'), it returns a 
value of noon.  You may want to add some time variation using rand to avoid firing off several thousand
Tweet posts all at one time....

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

So, rather than try to manipulate the queue, we can simply delete the tweet from the Tweet database.
When Sidekiq attempts to execute the job, the database lookup will fail, and the job will be
automatically deleted.

### Monitoring Sidekiq

Sidekiq includes a Sinatra instance that allows web-based monitoring of queues/jobs.  To add it to an existing
Sinatra system, add the following to the config.ru file:

```ruby
require 'sidekiq/web'
run Rack::URLMap.new('/' => Sinatra::Application, '/sidekiq' => Sidekiq::Web)
```

Then point your browser at <hostname>/sidekiq for a slick UI for monitoring and deleting jobs.



