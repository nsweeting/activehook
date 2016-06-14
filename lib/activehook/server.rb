require 'activehook/workers/runner'
require 'activehook/workers/queued'
require 'activehook/workers/failed'

module ActiveHook
  class Server
    def run
      Workers::Queued.run
      Workers::Failed.run
      sleep
    end
  end
end
