module ActiveHook
  module App
    class Middleware
      class << self
        attr_accessor :valid, :invalid, :not_created, :created
      end

      @invalid      = ->(_env) { [400, { "Content-Type" => "application/json" }, [{ valid: false }.to_json]] }
      @valid        = ->(_env) { [200, { "Content-Type" => "application/json" }, [{ valid: true }.to_json]] }
      @not_created  = ->(_env) { [400, { "Content-Type" => "application/json" }, [{ status: false }.to_json]] }
      @created      = ->(_env) { [200, { "Content-Type" => "application/json" }, [{ status: true }.to_json]] }

      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env
        @req = Rack::Request.new(env)

        if validation_request? then valid?
        elsif creation_request? then create?
        else @app.call(@env)
        end
      end

      def validation_request?
        @req.path == ActiveHook.config.validation_path && @req.get?
      end

      def creation_request?
        @req.path == ActiveHook.config.creation_path && @req.post?
      end

      def valid?
        if Validation.new(@req.params).start
          self.class.valid.call(@env)
        else
          self.class.invalid.call(@env)
        end
      end

      def create?
        if Creation.new(@req.params).start
          self.class.created.call(@env)
        else
          self.class.not_created.call(@env)
        end
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
