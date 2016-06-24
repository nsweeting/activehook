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
        elsif creation_request? then response(Creation)
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
          if klass.new(@req.params).start then { code: 200, status: true }
          else { code: 400, status: false }
          end
        [response[:code], { "Content-Type" => "application/json" }, [{ status: response[:status] }.to_json]]
      end
    end

    Validation = Struct.new(:params) do
      def start
        hook = { id: params['id'].to_i, key: params['key'] }
        ActiveHook::Validate.new(hook).perform
      rescue
        false
      end
    end

    Creation = Struct.new(:params) do
      def start
        hook = { uri: params['uri'], payload: JSON.parse(params['payload']) }
        ActiveHook::Hook.new(hook).perform
      rescue
        false
      end
    end
  end
end
