require 'spec_helper'

describe Erlen::Serializer::Base do
  subject { described_class }

  describe "#data_to_payload" do
    it "sets all the values" do
      data = { foo: 'bar' }
      payload = subject.hash_to_payload(data, TestBaseSerializerSchema)

      expect(payload.is_a? TestBaseSerializerSchema).to be_truthy
      expect(payload.foo).to eq('bar')
      expect(payload.valid?).to be_truthy
    end
  end

  describe "#payload_to_data" do
    # Depricated
    it "returns hash of payload data" do
      payload =  TestBaseSerializerSchema.new({ foo: 'bar' })
      data = subject.payload_to_hash(payload)

      expect(data).to include('foo')
      expect(data['foo']).to eq('bar')
    end

    it "returns hash of payload data" do
      payload =  TestBaseSerializerSchema.new({ foo: 'bar' })
      data = subject.payload_to_data(payload)

      expect(data).to include('foo')
      expect(data['foo']).to eq('bar')
    end
  end
end

class TestBaseSerializerSchema < Erlen::Schema::Base
  attribute :foo, String

  validate("Error Message") { |s| s.foo == 'bar' || s.foo == 1 }
end
