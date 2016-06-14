require 'test_helper'

class HookTest < Minitest::Test
  def setup
    @redis = Redis.new
  end

  def test_that_bad_uri_raises_exception
    hook = ActiveHook::Hook.new(uri: '5665', payload: { test: 1 })
    assert_raises(ActiveHook::Errors::Hook) { hook.perform }
  end

  def test_that_non_hash_payload_raises_exception
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: [])
    assert_raises(ActiveHook::Errors::Hook) { hook.perform }
  end

  def test_that_perform_adds_to_redis_list
    llen = @redis.llen('ah:queued')
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    hook.perform
    sleep 1
    assert @redis.llen('ah:queued') == llen + 1
  end
end
