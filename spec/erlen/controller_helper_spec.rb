require 'spec_helper'

describe Erlen::ControllerHelper do

  class JobRequestSchema < Erlen::BaseSchema
    attribute :name, String, required: true
    attribute :organization_id, Integer, required: true
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
    include Erlen::ControllerHelper

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
      request.request_parameters = JSON.dump({
        name: "foo",
        organization_id: 123
      })
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
      controller.request = request
      controller.validate_request_schema_for_show
      expect(controller.request_payload).to be_nil
      controller.show
      expect(controller.response_payload).to be_nil
      controller.validate_response_schema_for_create
      expect(controller.response_payload.valid?).to be_truthy
      expect(controller.response_schema).to be(JobResponseSchema)
    end
    it "invalidates malformed request body" do
      request = OpenStruct.new
      request.request_parameters = "notavalidjson"
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
      request.request_parameters = '{"wrongattribute": "foo"}'
      controller.request = request
      expect do
        controller.validate_request_schema_for_create
      end.to raise_error(Erlen::NoAttributeError)
      request = OpenStruct.new
      request.request_parameters = '{}'
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
end
