# ActiveHook
---

Fast and simple webhook delivery microservice for Ruby. **Please consider it under development at the moment.**

ActiveHook provides a scalable solution to your applications webhook sending needs. Its Redis-backed, with support for forking and threading - letting it send an enormous amount of webhooks in short order. Basically a much more focused version of a job processor such as Sidekiq, DelayedJob, Resque, etc. It includes the following:

- A server for the purpose of sending webhooks. With support for retry attempts.
- A client-side mixin module for the purpose of recieving and validating webhooks.
- A piece of Rack middleware for the purpose of performing validation.

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

Before starting, ensure you have a functioning Redis server available.

ActiveHook can be run in a few different ways.

#### Server Mode

 In order to send webhooks, we operate ActiveHook in server mode. This will be run as a seperate service beyond your web application (Rails, Sinatra, etc). To start the server simply type the following in your console.

    $ bundle exec activehook-server -c config/activehook.rb

By providing a path to a configuration file, we can setup ActiveHook with plain old ruby. Below is a list of currently available server options:

```ruby
# ActiveHook server configuration
ActiveHook.configure do |config|
  #Your redis server url
  config.redis_url = ENV['REDIS_URL']
  #The number of redis connections to provide
  config.redis_pool = 10
  #The number of forked workers to create for the server
  config.workers = 2
  #The number of queue threads to provide for each worker
  config.queue_threads = 2
  #The number of retry threads to provide for each worker
  config.retry_threads = 1
end
```

#### App Mode

In order to create webhooks, we operate ActiveHook in app mode. Like above, we need to provide information on Redis. We will also need to provide a path in our web application that can be used for validation. With Rails, we should place this configuration with our initializers.

```ruby
#IMPORTANT!
require 'activehook/app/base'

# ActiveHook app configuration
ActiveHook.configure do |config|
  #Your redis server url
  config.redis_url = ENV['REDIS_URL']
  #The number of redis connections to provide
  config.redis_pool = 5
  #The route to our webhook validator
  config.validation_path = '/hooks/validate'
end
```

With our app setup, we can create webhooks for processing. From within our application, all we have to do is:

```ruby
ActiveHook::Hook.new(uri: 'http://example.com/webhook', payload: { msg: 'My first webhook!' })
```

That's it! We provide a valid string URI, as well hash payload. ActiveHooks server will then attempt to send the webhook. If the webhook fails to be delivered, it will be sent to the retry queue. Delivery will be reattempted at the specified intervals, and eventually dropped if all attempts fail.

The default setting for failed webhooks is 3 more attempts at an interval of 3600 seconds (1 hour). You can change these values by including them in your hook initialization.

```ruby
ActiveHook::Hook.new(uri: 'http://example.com/webhook', payload: { msg: 'My first webhook!' }, retry_max: 3, retry_time: 3600)
```

We will go over app webhook validation after the following section...

#### Client Mode

ActiveHook provides a class as well as mixin module for the purposes of recieving webhooks and performing validation on them. The class should be used for personal projects and testing, while the mixin module can be integrated with other application gems.

Using the class is easy. We should first add use the following config:

```ruby
#IMPORTANT!
require 'activehook/client/base'

# ActiveHook client configuration
ActiveHook.configure do |config|
  #Your validation uri
  config.validation_uri = 'http://localhost:3000/hooks/validate'
end
```

If we were using Rails we could then do the following:

```ruby
class WebhooksController < ApplicationController

  def create
    @webhook = ActiveHook::Recieve.new(webhook_params)
    if @webhook.hook_valid?
      #We can now do stuff with the Hash @webhook.payload
    end
  end

  private

  def webhook_params
    params.require(:hook_id, :hook_key, :payload)
  end
end
```

Using the mixin module for our own classes would go like this:

```ruby
require 'activehook/client/base'

module MyApp
  class Webhook
    include ActiveHook::Client::Recieve

    #IMPORTANT! We will go over running the validation server next.
    VALIDATION_URI = 'http://myapp.com/hooks/validate'
  end
end
```

This would allow us to perform the same validation actions as in our Rails example, except we could use:

```ruby
@webhook = MyApp::Webhook.new(webhook_params)
if @webhook.hook_valid?
  #We can now do stuff with the Hash @webhook.payload
end
```

#### App Mode Validation

Sending webhooks is one thing - ensuring they are from who we want is another.

ActiveHook includes a piece of Rack middleware for the purpose of validation. When a client attempts to validate a webhook, they are sending a message back to your server. The message includes the hooks ID as well as key. These are are then cross-referenced. If they match, we provide the AOK.

In Rails, we would add the middleware like this:

```ruby
# In config/application.rb
config.middleware.use('ActiveHook::App::Middleware')
```

Or with Rackup files:

```ruby
# In config.ru
use ActiveHook::App::Middleware
```

ActiveHook also provides a straight lightweight validation microservice. This simply runs the middleware with Puma on its own.

    $ bundle exec activehook-app -p config/puma.rb -c config/activehook.rb

We must provide a path to our Puma config file as well as our ActiveHook app config file. Please read more about Puma if you need help with this.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nsweeting/activehook. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
