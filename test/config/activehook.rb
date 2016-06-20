ActiveHook.configure do |config|
  #Your redis server url
  config.redis_url = ENV['REDIS_URL']
  #The number of redis connections to provide
  config.redis_pool = 5
  #The number of forked workers to create for the server
  config.workers = 3
  #The number of queue threads to provide for each worker
  config.queue_threads = 5
  #The number of retry threads to provide for each worker
  config.retry_threads = 2
  #The maximum amount of retries to attempt for failed webhooks
  config.retry_max = 3
  #The amount of time between each retry attempt
  config.retry_time = 3600
end
