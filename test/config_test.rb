require 'test_helper'

class ConfigTest < Minitest::Test
  def test_that_redis_configure_works
    ActiveHook.configure do |c|
      c.redis_url = ENV['REDIS_URL']
      c.redis_pool = 20
    end
    assert ActiveHook.config.redis_url == ENV['REDIS_URL']
    assert ActiveHook.config.redis_pool == 20
  end

  def test_that_redis_connection_pool_works
    ActiveHook.configure do |c|
      c.redis_url = ENV['REDIS_URL']
      c.redis_pool = 10
    end
    assert ActiveHook.connection_pool.count == 10
  end

  def test_that_redis_setup_works
    ActiveHook.configure do |c|
      c.redis_url = ENV['REDIS_URL']
      c.redis_pool = 5
    end
    assert ActiveHook.redis.connection.ping
  end

  def test_that_config_has_defaults
    ActiveHook.reset
    assert ActiveHook.config.redis_pool == 5
    assert ActiveHook.config.threads_max == 5
  end
end
