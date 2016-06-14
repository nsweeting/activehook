require 'activehook/workers/runner'
require 'activehook/workers/queued'
require 'activehook/workers/failed'

module ActiveHook
  class Server
    def run
      workers_for_queued
      worker_for_failed
      sleep
    end

    private

    def workers_for_queued
      (1..ActiveHook.config.workers_queued).each { Workers::Queued.new }
    end

    def worker_for_failed
      Workers::Failed.new
    end
  end
end
