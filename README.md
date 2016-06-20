# ActiveHook
---

Fast and simple webhook microservice for Ruby. **Please consider it under development at the moment.**

ActiveHook provides a scalable solution to your applications webhook sending needs. Its Redis-backed, with support for forking and threading - letting it send an enormous amount of webhooks in short order. Basically a much more focused version of a job processor such as Sidekiq, DelayedJob, Resque, etc.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activehook'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activehook

## Getting Started

Before starting, ensure you have a functioning Redis server available. ActiveHook runs as a seperate server beyond Rails, Sinatra, etc. To start the server simply type the following in your console.

    $ bundle exec activehook -c config/initializers/activehook.rb

By providing a path to a configuration file, we can setup ActiveHook with plain old ruby. Below is a list of currently available options:

```ruby
ActiveHook.configure do |config|
  #Your redis server url
  config.redis_url = ENV['REDIS_URL']
  #The number of redis connections to provide
  config.redis_pool = 5
  #The number of forked workers to create for the server
  config.workers = 2
  #The number of queue threads to provide for each worker
  config.queue_threads = 5
  #The number of retry threads to provide for each worker
  config.retry_threads = 2
  #The maximum amount of retries to attempt for failed webhooks
  config.retry_max = 3
  #The amount of time between each retry attempt
  config.retry_time = 3600
end
```

Queuing a webhook for processing is easy. From within our application, all we have to do is:

```ruby
ActiveHook::Hook.new(uri: 'http://example.com/webhook', payload: { msg: 'My first webhook!' })
```

That's it! We provide a valid string URI, as well hash payload. ActiveHooks queue threads will then attempt to send the webhook. If the webhook fails to be delivered, it will be sent to the retry queue. Delivery will be reattempted at the specified intervals, and eventually dropped if all attempts fail.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nsweeting/activehook. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
