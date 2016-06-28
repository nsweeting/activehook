# ActiveHook
[![Code Climate](https://codeclimate.com/github/nsweeting/activehook/badges/gpa.svg)](https://codeclimate.com/github/nsweeting/activehook) [![Gem Version](https://badge.fury.io/rb/activehook.svg)](https://badge.fury.io/rb/activehook)

Fast and simple webhook delivery microservice for Ruby. **Please consider it under development at the moment.**

ActiveHook provides a scalable solution to your applications webhook sending needs. Its Redis-backed, with support for forking and threading - letting it send an enormous amount of webhooks in short order. Basically a much more focused version of a job processor such as Sidekiq, DelayedJob, Resque, etc. It includes the following:

- A server for the purpose of sending webhooks. With support for retry attempts.
- A client-side mixin module for the purpose of recieving and validating webhooks.
- A piece of Rack middleware for providing server-side validation.

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

ActiveHook can be operated in a few different ways.

#### The Server

 In order to send webhooks, we run the ActiveHook server. This is a seperate service beyond your web application (Rails, Sinatra, etc). To start the server simply type the following in your console.

    $ bundle exec activehook-server -c config/activehook.rb

By providing a path to a configuration file, we can setup ActiveHook with plain old ruby. In a rails application, this should be placed in your config folder. Below is a list of currently available server options:

```ruby
# ActiveHook server configuration
ActiveHook.configure do |config|
  # Your redis server url
  config.redis_url = ENV['REDIS_URL']
  # The number of redis connections to provide
  config.redis_pool = 10
  # The number of forked workers to create for the server
  config.workers = 2
  # The number of queue threads to provide for each worker
  config.queue_threads = 2
  # The number of retry threads to provide for each worker
  config.retry_threads = 1
end
```

#### Your Application

Before we can create webhooks within our application, we will need to do some setup. With Rails, we should place this configuration with your initializers. Below is a list of currently available application options:

```ruby
#IMPORTANT!
require 'activehook/app'

# ActiveHook app configuration
ActiveHook.configure do |config|
  #Your redis server url
  config.redis_url = ENV['REDIS_URL']
  #The number of redis connections to provide
  config.redis_pool = 5
  #The route to the webhook validator if you want to enable server-side validation
  config.validation_path = '/hooks/validate'
end
```

To provide webhooks to your users, you will also need to allow them to specify a URI and token. In Rails, we can do this by creating a migration like below:

```ruby
add_column :users, :webhook_uri, :string
add_column :users, :webhook_token, :string
```

With our app setup, we can create webhooks for processing. From within our application, all we have to do is:

```ruby
hook = ActiveHook::Hook.new(token: webhook_token, uri: webhook_uri, payload: { msg: 'My first webhook!' })
if hook.save # We can also do save!, which would raise an exception upon failure.
  # Success.
else
  # Failed - access errors at hook.errors
end

```

That's it! We provide a valid string token and URI, as well hash payload. ActiveHooks server will then attempt to send the webhook. If the webhook fails to be delivered, it will be sent to the retry queue. Delivery will be reattempted at the specified intervals, and eventually dropped if all attempts fail.

The default setting for failed webhooks is 3 more attempts at an interval of 3600 seconds (1 hour). You can change these values by including them in your hook initialization.

```ruby
ActiveHook::Hook.new(token: webhook_token, uri: webhook_uri, payload: { msg: 'My first webhook!' }, retry_max: 3, retry_time: 3600)
```

#### Recieving

ActiveHook provides a class as well as mixin module for the purposes of recieving webhooks and performing validation on them. The class should be used for personal projects and testing, while the mixin module can be integrated with other application gems.

Using the class or mixin, we are able to perform both client-side and server-side validation.

Using the class is easy. We should first add the following config:

```ruby
#IMPORTANT!
require 'activehook/client'

# ActiveHook client configuration
ActiveHook.configure do |config|
  # Your validation uri for server-side validation
  config.validation_uri = 'http://localhost:3000/hooks/validate'
  # Your validation token for client-side validation
  config.validation_token = ENV['WEBHOOK_TOKEN']
end
```

If we were using Rails we could then do the following:

```ruby
class WebhooksController < ApplicationController

  def create
    @webhook = ActiveHook::Recieve.new(request: request)
    if @webhook.signature_valid?
      #We can now do stuff with the Hash @webhook.payload
    end
  end
end
```

The signature_valid? method will perform client-side validation. We can also perform server-side validation by doing the following:

```ruby
@webhook.server_valid?
```

Using the mixin module for our own classes would go like this:

```ruby
require 'activehook/client'

module MyApp
  class Webhook
    include ActiveHook::Client::Recieve

    VALIDATION_TOKEN = ENV['WEBHOOK_TOKEN']
    #IMPORTANT! We will go over running the validation server next.
    VALIDATION_URI = 'http://myapp.com/hooks/validate'
  end
end
```

This would allow us to perform the same validation actions as in our Rails example, except we could use:

```ruby
@webhook = MyApp::Webhook.new(request: request)
if @webhook.signature_valid?
  #We can now do stuff with the Hash @webhook.payload
end
```

#### Server Validation

Along with client-side validation, ActiveHook also allows you to setup server-side validation. This utilizes a piece of Rack middleware.

When a client attempts to validate a webhook, they are sending a message back to your server. The message includes the hooks ID as well as key. These are are then cross-referenced with the server records. If they match, we provide the AOK.

We set the address that the middleware uses from our config file (application config described above):

```ruby
config.validation_path = '/hooks/validate'
```

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
