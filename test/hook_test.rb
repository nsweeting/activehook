require 'test_helper'
require 'activehook/app/base'

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

  def test_that_non_integer_created_at_raises_exception
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    hook.created_at = 'Test'
    assert_raises(ActiveHook::Errors::Hook) { hook.perform }
  end

  def test_that_non_integer_retry_time_raises_exception
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 }, retry_time: 'Test')
    assert_raises(ActiveHook::Errors::Hook) { hook.perform }
  end

  def test_that_non_integer_retry_max_raises_exception
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 }, retry_max: 'Test')
    assert_raises(ActiveHook::Errors::Hook) { hook.perform }
  end

  def test_that_new_hook_sets_key
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    assert hook.key
  end

  def test_that_new_hook_sets_created_at
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    assert hook.created_at
  end

  def test_that_to_json_returns_json
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    json = hook.to_json
    new_hook = JSON.parse(json)
    assert new_hook['uri'] == hook.uri
  end

  def test_that_secure_payload_returns_json
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    json = hook.secure_payload
    new_hook = JSON.parse(json)
    assert new_hook['hook_key'] == hook.key
  end

  def test_that_retry_max_time_returns_correct_number
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 }, retry_time: 30, retry_max: 2)
    assert hook.retry_max_time == 60
  end

  def test_that_non_retry_question_works
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 }, retry_time: 0, retry_max: 0)
    assert !hook.retry?
  end

  def test_that_retry_question_works
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 }, retry_time: 3600, retry_max: 3)
    assert hook.retry?
  end

  def test_that_retry_at_returns_time_integer
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    assert Time.now.to_i < hook.retry_at
  end

  def test_that_fail_at_returns_time_integer
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    assert Time.now.to_i < hook.fail_at
  end

  def test_that_perform_adds_to_redis_queue
    llen = @redis.llen('ah:queue')
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    hook.perform
    sleep 1
    assert @redis.llen('ah:queue') == llen + 1
  end

  def test_that_perform_adds_to_redis_validation
    zcount = @redis.zcount('ah:validation', 0, 10000000000)
    hook = ActiveHook::Hook.new(uri: 'http://test.com/', payload: { test: 1 })
    hook.perform
    sleep 1
    assert @redis.zcount('ah:validation', 0, 10000000000) == zcount + 1
  end
end
