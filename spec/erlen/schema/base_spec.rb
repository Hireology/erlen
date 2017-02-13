require 'spec_helper'

describe Erlen::Schema::Base do
  subject { described_class }

  describe "#initialize" do
    it "sets all the values given a hash" do
      payload = TestBaseSchema.new({ foo: 'bar' })

      expect(payload.class.schema_attributes).to include(:foo)
      expect(payload.foo).to eq('bar')
    end

    it "sets all the values given an object" do
      payload = TestBaseSchema.import(TestObj.new)

      expect(payload.class.schema_attributes).to include(:foo)
      expect(payload.foo).to eq('bar')
    end
  end

  describe "#valid?" do
    it "returns valid only if payload is perfect" do
      valid = TestBaseSchema.new({ foo: 'bar' })
      expect(valid.valid?).to be_truthy

      valid = TestBaseSchema.new({ foo: 1 })
      expect(valid.valid?).to be_falsey
    end
  end

  describe "#method_missing" do
    it "sets and gets attribute by method" do
      missing = TestBaseSchema.new({ foo: 'NOT' })
      expect(missing.valid?).to be_falsey
      expect(missing.foo).to eq('NOT')

      missing.foo = 'bar'
      expect(missing.valid?).to be_truthy
      expect(missing.foo).to eq('bar')
      expect(missing.bar).to eq('bar')
    end
  end

  describe "#errors" do
    it "compiles errors of everything wrong" do
      errors = TestBaseSchema.new({ foo: 13 })
      errors.valid?
      expect(errors.errors).to eq(["foo: 13 is not String", "Error Message"])
    end
  end

  describe '#import' do
    it 'imports from a hash' do
      payload = TestBaseSchema.import(foo: 'bar', custom: 1)

      expect(payload.foo).to eq('bar')
      expect(payload.custom).to eq(1)
    end

    it 'imports from an obj' do
      payload = TestBaseSchema.import(TestObj.new)

      expect(payload.foo).to eq('bar')
      expect(payload.custom).to eq(nil)
    end
  end

  describe '#to_data' do
    it 'converts to hash' do
      payload = TestBaseSchema.import(TestObj.new)
      data = payload.to_hash

      expect(data['foo']).to eq('bar')
      expect(data['custom']).to eq(nil)
    end

    it 'converts to hash' do
      payload = TestBaseSchema.import(TestObj.new)
      data = payload.to_data

      expect(data['foo']).to eq('bar')
      expect(data['custom']).to eq(nil)
    end
  end
end

class TestBaseSchema < Erlen::Schema::Base
  attribute :foo, String, { alias: :bar }
  attribute :custom, Integer

  validate("Error Message") { |s| s.foo == 'bar' || s.foo == 1 }
end

class TestObj
  def bar
    'bar'
  end
end
