require 'test_helper'
require 'activehook/server/base'

class ConfigTest < Minitest::Test

  def test_that_redis_configure_works
    ActiveHook.configure do |c|
      c.redis_url = ENV['REDIS_URL']
      c.redis_pool = 20
    end
    assert ActiveHook.config.redis_url == ENV['REDIS_URL']
    assert ActiveHook.config.redis_pool == 20
  end

  def test_that_redis_setup_works
    ActiveHook.configure do |c|
      c.redis_url = ENV['REDIS_URL']
      c.redis_pool = 10
    end
    assert ActiveHook.redis.with(&:ping)
  end
end
