module ActiveHook
  module App
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env
        @req = Rack::Request.new(env)

        if validation_request? then response(Validation)
        #Not enabling webhook creation yet.
        #elsif creation_request? then response(Creation)
        else @app.call(@env)
        end
      end

      def validation_request?
        @req.path == ActiveHook.config.validation_path && @req.get?
      end

      def creation_request?
        @req.path == ActiveHook.config.creation_path && @req.post?
      end

      def response(klass)
        response =
          if klass.new(@req).start then { code: 200, status: true }
          else { code: 400, status: false }
          end
        [response[:code], { "Content-Type" => "application/json" }, [{ status: response[:status] }.to_json]]
      end
    end

    Validation = Struct.new(:req) do
      def start
        hook = { id: req.params['id'].to_i, key: req.params['key'] }
        ActiveHook::Validate.new(hook).perform
      rescue
        false
      end
    end

    Creation = Struct.new(:req) do
      def start
        hook = JSON.parse(req.body.read)
        ActiveHook::Hook.new(hook).perform
      rescue
        false
      end
    end
  end
end
