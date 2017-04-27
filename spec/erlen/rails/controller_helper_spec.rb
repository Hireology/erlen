require 'spec_helper'

describe Erlen::Rails::ControllerHelper do

  class JobRequestSchema < Erlen::Schema::Base
    attribute :name, String, required: true
    attribute :organization_id, Integer, required: true
    attribute :query, String
  end

  class JobResponseSchema < JobRequestSchema
    attribute :id, Integer, required: true
  end

  class FauxController
    attr_accessor :request, :response
    def self.before_action(callback, opts = {}); end
    def self.after_action(callback, opts = {}); end
    def initialize
      @response = OpenStruct.new
    end
    def render(options={}, extra_options={}, &blk)
      response.body = options[:json]
    end
  end

  class JobsController < FauxController
    include Erlen::Rails::ControllerHelper

    action_schema :create, request: JobRequestSchema, response: JobResponseSchema
    action_schema :show, response: JobResponseSchema

    def create
      job = JobResponseSchema.import(request_payload)
      job.id = 1
      render payload: job, status: 201
    end

    def show
      job = {
        id: 2,
        name: "bar",
        organization_id: 999
      }
      render json: job.to_json, status: 200
    end
  end

  subject { described_class }

  describe "schema validation" do
    let(:controller) { JobsController.new }
    it "validates create schemas" do
      request = OpenStruct.new
      body = OpenStruct.new
      request.body = body
      request.query_parameters = {}
      body.read = {
        name: "foo",
        organization_id: 123
      }.to_json
      controller.request = request
      # manually trigger before action
      controller.validate_request_schema_for_create
      expect(controller.request_payload.valid?).to be_truthy
      expect(controller.request_payload.class).to be(JobRequestSchema)
      controller.create
      controller.validate_response_schema_for_create
      expect(controller.response_payload.valid?).to be_truthy
      expect(controller.response_schema).to be(JobResponseSchema)
    end
    it "validates show schema (without a proper payload)" do
      request = OpenStruct.new
      request.body = ""
      request.query_parameters = {}
      controller.request = request
      controller.validate_request_schema_for_show
      expect(controller.request_payload).to be_nil
      controller.show
      expect(controller.response_payload).to be_nil
      controller.validate_response_schema_for_create
      expect(controller.response_payload.valid?).to be_truthy
      expect(controller.response_schema).to be(JobResponseSchema)
    end
    it 'sets request parameters' do
      request = OpenStruct.new
      body = OpenStruct.new
      request.body = body
      body.read = {
        name: "foo",
        organization_id: 123
      }.to_json
      request.query_parameters = { query: 'param', bad: true }
      controller.request = request
      controller.validate_request_schema_for_create

      # puts controller.request_payload.inspect
      expect(controller.request_payload.query).to eq('param')
    end
    it "invalidates malformed request body" do
      request = OpenStruct.new
      body = OpenStruct.new
      request.body = body
      body.read = "notavalidjson"
      controller.request = request
      expect do
        controller.validate_request_schema_for_create
      end.to raise_error(Erlen::InvalidRequestError)
    end
    it "invalidates malformed response body" do
      response = OpenStruct.new
      response.body = "notavalidjson"
      controller.response = response
      expect do
        controller.validate_response_schema_for_create
      end.to raise_error(Erlen::InvalidResponseError)
    end
    it "invalidates inappropriate request payload" do
      request = OpenStruct.new
      body = OpenStruct.new
      request.query_parameters = {}
      request.body = body
      body.read = { wrongattribute: 'foo' }.to_json
      controller.request = request
      expect do
        controller.validate_request_schema_for_create
      end.to raise_error(Erlen::NoAttributeError)
      request = OpenStruct.new
      body = OpenStruct.new
      request.query_parameters = {}
      request.body = body
      body.read = {}.to_json
      controller.request = request
      expect do
        controller.validate_request_schema_for_create
      end.to raise_error(Erlen::ValidationError)
    end
    it "invalidates inappropriate response payload" do
      response = OpenStruct.new
      response.body = '{"wrongattribute": "bar"}'
      controller.response = response
      expect do
        controller.validate_response_schema_for_create
      end.to raise_error(Erlen::NoAttributeError)
      response.body = '{}'
      controller.response = response
      expect do
        controller.validate_response_schema_for_create
      end.to raise_error(Erlen::ValidationError)
    end
  end

  describe "options data payload" do
    context "stuff" do
      class TestController7 < FauxController
        include Erlen::Rails::ControllerHelper
        def self.before_action(callback, opts = {}); end
        options_schema :true

        def options
        end
      end
      let(:empty_controller) { TestController7.new }

      it "handles empty options" do
        empty_controller.render_options_schema_data
        empty_controller.options
        expect(empty_controller.response.body).to eq({})
      end
    end

    context "basic functionality" do
      class TestController1 < FauxController
        include Erlen::Rails::ControllerHelper
        def self.before_action(callback, opts = {}); end

        action_schema :create, response: JobResponseSchema, options: true
        action_schema :show, response: JobResponseSchema, options: true
        options_schema :true

        def options
        end
      end

      let(:controller) { TestController1.new }

      it "builds options response for a single RESTful action" do
        controller.add_options_schema_for_create
        controller.render_options_schema_data
        controller.options
        expect(controller.response.body).to eq({
          "POST" => JobResponseSchema.to_json_schema,
        })
      end

      it "builds options response for a multiple RESTful actions" do
        controller.add_options_schema_for_create
        controller.add_options_schema_for_show
        controller.render_options_schema_data
        controller.options
        expect(controller.response.body).to eq({
          "POST" => JobResponseSchema.to_json_schema,
          "GET" => JobResponseSchema.to_json_schema,
        })
      end
    end

    context "more complex actions" do
      class TestController4 < FauxController
        include Erlen::Rails::ControllerHelper
        def self.before_action(callback, opts = {}); end

        action_schema :create, response: JobResponseSchema, options: true
        action_schema :show, response: JobResponseSchema, options: true
        action_schema :destroy, response: JobResponseSchema, options: true
        action_schema :update, response: JobResponseSchema, options: true
        action_schema :index, response: JobResponseSchema, options: true
        action_schema :edit, response: JobResponseSchema, options: true
        options_schema :true

        def options
        end
      end

      let(:controller) { TestController4.new }

      it "builds options for all restful routes" do
        controller.add_options_schema_for_create
        controller.add_options_schema_for_show
        controller.add_options_schema_for_index
        controller.add_options_schema_for_destroy
        controller.add_options_schema_for_update
        controller.render_options_schema_data
        controller.options
        expect(controller.response.body).to eq({
          "POST" => JobResponseSchema.to_json_schema,
          "GET" => JobResponseSchema.to_json_schema,
          "DELETE" => JobResponseSchema.to_json_schema,
          "PUT" => JobResponseSchema.to_json_schema,
        })
      end
    end

    context "when determine if options data should be created for an action" do
      class TestController2 < FauxController
        include Erlen::Rails::ControllerHelper
        def self.before_action(callback, opts = {}); end

        action_schema :create, response: JobResponseSchema, options: true
        action_schema :show, response: JobResponseSchema, options: false
        options_schema :true

        def options
        end
      end
      let(:controller) { TestController2.new }

      it "only builds options response for an action if action_schema options is set to true" do
        controller.add_options_schema_for_create
        controller.add_options_schema_for_show if controller.respond_to?(:add_options_schema_for_show)
        controller.render_options_schema_data
        controller.options
        expect(controller.response.body).to eq({
          "POST" => JobResponseSchema.to_json_schema,
        })
      end
    end

    context "when determine if options data should be created for any action" do
      class TestController3 < FauxController
        include Erlen::Rails::ControllerHelper
        attr_accessor :option_schemas
        def self.before_action(callback, opts = {}); end

        action_schema :create, response: JobResponseSchema, options: true
        action_schema :show, response: JobResponseSchema, options: true
        options_schema :false

        def options
        end
      end
      let(:controller) { TestController3.new }

      it "builds option data but does not auto-render response unless option_schema = :true" do
        controller.add_options_schema_for_create
        controller.add_options_schema_for_show
        controller.render_options_schema_data if controller.respond_to?(:render_options_schema_data)
        controller.options
        expect(controller.response.body).to eq(nil)
        expect(controller.option_schemas).to eq(
          "POST" => JobResponseSchema.to_json_schema,
          "GET" => JobResponseSchema.to_json_schema,
        )
      end
    end
  end
end
