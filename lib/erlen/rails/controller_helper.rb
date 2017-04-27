module Erlen; module Rails
  # This helper module can be included in a controller to define action
  # schemas, which creates before/after action callbacks to validate
  # either/both request or/and response payloads.
  module ControllerHelper
    # This module contains class methods that will extend the class that
    # inherits #ControllerHelper
    module ClassMethods

      # Specifies a schema for the action. If request schema is specified,
      # it will create a before action callback to deserialize and validate the
      # payload. If response schema is specified, it will create a after
      # action callback to serialize and validate the response payload. If
      # render method is used prior to the after action callback, the
      # validation will be skipped during the callback.
      #
      # @param action [String] the name of the action
      # @param request [Schema::Base] the schema for request body
      # @param response [Schema::Base] the schema for response body
      def action_schema(action, request: nil, response: nil, options: false)
        __erlen__create_before_action(action, request, response)
        __erlen__create_after_action(action, response)
        __erlen_create_options_response(action, response) if options && response
        nil
      end

      def options_schema(on=:false)
        if(on == :true)
          define_method(:render_options_schema_data) do
            render json: (@option_schemas || {}), status: 200
          end

          send(:"before_action", :render_options_schema_data, only: :options)
        end
      end

      def __erlen_create_options_response(action, response_schema)

        define_method(:"add_options_schema_for_#{action}") do
          new_option = Filters::CreateSchemaOptionsData.run(action, response_schema)
          @option_schemas = (@option_schemas || {}).merge(new_option)
        end

        send(:"before_action", :"add_options_schema_for_#{action}", only: :options)
      end

      def __erlen__create_before_action(action, request_schema, response_schema)
        define_method(:"validate_request_schema_for_#{action}") do
          # memoize both of them here
          @request_schema = request_schema
          @response_schema = response_schema
          if request_schema
            begin
              @__erlen__request_payload = Erlen::Serializer::JSON.from_json(request.body.read, request_schema)
              request.query_parameters.each do |k, v|
                next unless request_schema.schema_attributes.keys.include?(k.to_sym)

                @__erlen__request_payload.send("#{k}=", v)
              end

            rescue JSON::ParserError
              raise InvalidRequestError.new("Could not parse request body")
            end

            raise ValidationError.from_errors(@__erlen__request_payload.errors) unless @__erlen__request_payload.valid?
          end
        end
        send(:"before_action", :"validate_request_schema_for_#{action}", only: action)
      end

      private

      def __erlen__create_after_action(action, schema)
        define_method(:"validate_response_schema_for_#{action}") do
          return if @validated
          begin
            json = JSON.parse(response.body)
          rescue JSON::ParserError
            raise InvalidResponseError.new("Could not parse response body")
          end
          @__erlen__response_payload = schema.new(json)
          raise ValidationError.from_errors(@__erlen__response_payload.errors) unless @__erlen__response_payload.valid?
        end
      end
    end

    # When this module is included, extend the class to have class methods
    # as well.
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    # This contains the current action's request schema
    attr_reader :request_schema

    # This contains the current action's response schema
    attr_reader :response_schema

    # Allows rendering of a payload. This operates as the original render if
    # options do not include payload.
    #
    # @note Overridding ActionController::Base#render. Using the exact
    # signature for the method to avoid confusion.
    # http://apidock.com/rails/ActionController/Base/render
    #
    # @param options [Hash]
    # @param extra_options [Hash]
    # @param block [Proc]
    #
    def render(options={}, extra_options={}, &block)
      if options.include?(:payload)
        payload = options.delete(:payload)
        render_payload(payload, options, extra_options=extra_options, &block)
      else
        @validated = false
        @__erlen__response_payload = nil
        super
      end
    end

    # Payload is an instance of Schema::Base class, representing either a
    # request body or response body, validated against the schema. This
    # particular method is only used to retrieve the request payload.
    def request_payload
      @__erlen__request_payload.deep_clone if @__erlen__request_payload
    end

    # Reads the current response payload, an instance of Schema::Base class.
    # You can set this value using render().
    def response_payload
      @__erlen__response_payload.deep_clone if @__erlen__response_payload
    end

    private

    def render_payload(payload, opts={}, extra_opts={}, &blk)
      raise ValidationError.from_errors(payload.errors) unless payload.valid?
      raise ValidationError.new('Response Scheama does not match') if @response_schema && !payload.is_a?(@response_schema)

      opts.update({json: Erlen::Serializer::JSON.to_json(payload)})
      render(opts, extra_opts, &blk) # NOTE: indirect recursion!
      @validated = true # set this after recursive render()
      @__erlen__response_payload = payload
    end

  end
end; end
