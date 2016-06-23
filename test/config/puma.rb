#Puma config
workers Integer(5)
threads_count = Integer(5)
threads threads_count, threads_count

preload_app!

rackup DefaultRackup
port ENV['PORT'] || 3000
