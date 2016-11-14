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

    request_schema :create, JobRequestSchema

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
    end
    it "invalidates malformed request body" do
      request = OpenStruct.new
      request.request_parameters = "notavalidjson"
      controller.request = request
      expect do
        controller.validate_request_schema_for_create
      end.to raise_error(Erlen::InvalidRequestError)
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
  end
end
