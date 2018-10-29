require 'spec_helper'

class TestBaseSchema < Erlen::Schema::Base
  attribute :foo, String, { alias: :bar }
  attribute :custom, Integer
  attribute :default, Integer, default: 10
  collection :coll_attr, String

  validate("Error Message") { |s| s.foo == 'bar' || s.foo == 1 }
end

class TestTypeSchema < Erlen::Schema::Base
  attribute :int, Integer
  attribute :flt, Float
  attribute :bool, Boolean
  attribute :bool2, Boolean
  attribute :bool3, Boolean
  attribute :bool4, Boolean
  attribute :dt, DateTime
  attribute :d, Date
end

class TestCollectionSchema < Erlen::Schema::Base
  collection :coll_attr, String, { required: true } { |p| p.count > 0 }
end

class TestObj
  def bar
    'bar'
  end

  def with_arg(opts)
    opts[:con]
  end
end

class TestSubSchema < TestBaseSchema
end

class TestContextSchema < TestBaseSchema
  attribute :with_arg, String
end

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

    it 'handles type coercions' do
      data = {
        int: '1',
        flt: '1.1',
        bool: 'true',
        bool2: 't',
        bool3: 'f',
        bool4: 0,
        dt: '1/1/2017/',
        d: '2018-02-03'
      }
      payload = TestTypeSchema.new(data)

      expect(payload.int).to eq(1)
      expect(payload.flt).to eq(1.1)
      expect(payload.bool).to eq(true)
      expect(payload.bool2).to eq(true)
      expect(payload.bool3).to eq(false)
      expect(payload.bool4).to eq(false)
      expect(payload.dt).to eq(DateTime.parse('1/1/2017'))
      expect(payload.d).to eq(Date.parse('2018-02-03'))
    end

    it 'returns correct values if they do not need to be coerced' do
      data = {
        int: 1,
        flt: 1.1,
        bool: true,
        bool2: false,
        dt: DateTime.parse('1/1/2017'),
        d: Date.parse('2018-02-03')
      }
      payload = TestTypeSchema.new(data)

      expect(payload.int).to eq(1)
      expect(payload.flt).to eq(1.1)
      expect(payload.bool).to eq(true)
      expect(payload.bool2).to eq(false)
      expect(payload.dt).to eq(DateTime.parse('1/1/2017'))
      expect(payload.d).to eq(Date.parse('2018-02-03'))
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

  describe "#attribute_provided?" do
    it "returns true when a value is provided" do
      schema = TestBaseSchema.new({ foo: 'bar' })
      expect(schema.attribute_provided?(:foo)).to be_truthy

      schema = TestBaseSchema.import({ foo: 'bar' })
      expect(schema.attribute_provided?(:foo)).to be_truthy
    end

    it "returns true even when the provided value is nil" do
      schema = TestBaseSchema.new({ foo: nil })
      expect(schema.attribute_provided?(:foo)).to be_truthy

      schema = TestBaseSchema.import({ foo: nil })
      expect(schema.attribute_provided?(:foo)).to be_truthy
    end

    it "returns true when a default value is set" do
      schema = TestBaseSchema.new({})
      expect(schema.attribute_provided?(:default)).to be_truthy

      schema = TestBaseSchema.import({})
      expect(schema.attribute_provided?(:default)).to be_truthy
    end

    it "returns false for unknown values" do
      schema = TestBaseSchema.new({ foo: 'bar' })
      expect(schema.attribute_provided?(:baz)).to be_falsey

      schema = TestBaseSchema.import({ foo: 'bar' })
      expect(schema.attribute_provided?(:baz)).to be_falsey
    end

    it "returns false when a known value is not provided" do
      schema = TestBaseSchema.new({ foo: 'bar' })
      expect(schema.attribute_provided?(:custom)).to be_falsey

      schema = TestBaseSchema.import({ foo: 'bar' })
      expect(schema.attribute_provided?(:custom)).to be_falsey
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

    it 'responds to an attribute or alias' do
      missing = TestBaseSchema.new({ foo: 'NOT' })

      expect(missing.respond_to?(:foo)).to be_truthy
      expect(missing.respond_to?(:bar)).to be_truthy
      expect(missing.respond_to?(:foo=)).to be_truthy
      expect(missing.respond_to?(:bar=)).to be_falsey
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

    it 'imports from a hash with string keys' do
      payload = TestBaseSchema.import('foo' => 'bar', 'custom' => 1)

      expect(payload.foo).to eq('bar')
      expect(payload.custom).to eq(1)
    end

    it 'imports from an obj' do
      payload = TestBaseSchema.import(TestObj.new)

      expect(payload.foo).to eq('bar')
      expect(payload.custom).to eq(nil)
    end

    it 'defaults hash attributes' do
      payload = TestBaseSchema.import(foo: 'bar', custom: 1)
      expect(payload.default).to eq(10)
    end

    it 'imports from an obj with context' do
      payload = TestContextSchema.import(TestObj.new, con: 'text')

      expect(payload.with_arg).to eq('text')
    end

    context 'aliasing' do
      it 'imports from an obj' do
        payload = TestBaseSchema.import(TestObj.new)

        expect(payload.foo).to eq('bar')
        expect(payload.custom).to eq(nil)
      end

      it 'imports from a hash' do
        payload = TestBaseSchema.import(bar: 'bar')

        expect(payload.foo).to eq('bar')
      end
    end
  end

  describe '#import_array' do
    it 'takes in an array and returns a payload' do
      payload = TestBaseSchema.import_array([TestObj.new])

      expect(payload.class.element_type).to eq(TestBaseSchema)

      data = payload.to_data
      expect(data[0]['foo']).to eq('bar')
    end
  end

  describe '#new_array' do
    it 'takes in an array and returns a payload' do
      payload = TestBaseSchema.new_array([TestObj.new])

      expect(payload.class.element_type).to be(TestBaseSchema)

      data = payload.to_data
      expect(data[0]['foo']).to eq('bar')
    end
  end

  describe '#to_data' do
    it 'converts to hash' do
      payload = TestBaseSchema.import(TestObj.new)
      data = payload.to_hash

      expect(data['foo']).to eq('bar')
      expect(data['custom']).to eq(nil)
    end

    it 'converts to data' do
      payload = TestBaseSchema.import(TestObj.new)
      data = payload.to_data

      expect(data['foo']).to eq('bar')
      expect(data['custom']).to eq(nil)
    end

    it 'does not include undefined attribute' do
      payload = TestBaseSchema.new
      data = payload.to_data
      expect(data.include?('foo')).to be_falsey
      expect(data.include?('custom')).to be_falsey
    end
  end

  describe 'collection' do
    it 'initializes the attribute as an array' do
      payload = TestBaseSchema.import(coll_attr: %w[foo bar])
      data = payload.to_data

      expect(data['coll_attr']).to include('foo')
      expect(data['coll_attr']).to include('bar')
    end

    it 'runs collections validations' do
      payload = TestCollectionSchema.import(coll_attr: [])
      expect(payload.valid?).to be_falsey
      expect(payload.errors).to eq(['coll_attr is not valid'])

      payload = TestCollectionSchema.import({})
      expect(payload.valid?).to be_falsey
      expect(payload.errors).to eq(['coll_attr is not valid'])
    end
  end

  describe '#==' do
    it 'is equal to another of the same class and data' do
      payload1 = TestBaseSchema.import(foo: 'bar', custom: 1)
      payload2 = TestBaseSchema.import(foo: 'bar', custom: 1)

      expect(payload1 == payload2).to be(true)
    end

    it 'is not equal to another if they differ in data' do
      payload1 = TestBaseSchema.import(foo: 'bar', custom: 1)
      payload2 = TestBaseSchema.import(foo: 'baz', custom: 1)

      expect(payload1 == payload2).to be(false)
    end

    it 'is not equal to another if they differ in class' do
      payload1 = TestBaseSchema.import(foo: 'bar', custom: 1)
      payload2 = TestSubSchema.import(foo: 'bar', custom: 1)

      expect(payload1 == payload2).to be(false)
    end
  end

  describe '#eql?' do
    it 'is equal to another of the same class and data' do
      payload1 = TestBaseSchema.import(foo: 'bar', custom: 1)
      payload2 = TestBaseSchema.import(foo: 'bar', custom: 1)

      expect(payload1.eql?(payload2)).to be(true)
    end

    it 'is not equal to another if they differ in data' do
      payload1 = TestBaseSchema.import(foo: 'bar', custom: 1)
      payload2 = TestBaseSchema.import(foo: 'baz', custom: 1)

      expect(payload1.eql?(payload2)).to be(false)
    end

    it 'is not equal to another if they differ in class' do
      payload1 = TestBaseSchema.import(foo: 'bar', custom: 1)
      payload2 = TestSubSchema.import(foo: 'bar', custom: 1)

      expect(payload1.eql?(payload2)).to be(false)
    end
  end

  describe '#as_json' do
    it 'uses the hash of to_data for json conversion' do
      payload = TestBaseSchema.import(foo: 'bar', custom: 1)

      expect(payload).not_to receive(:warn)
      expect(payload.as_json).to eq(
        'foo' => 'bar',
        'custom' => 1,
        'default' => 10,
        'coll_attr' => [],
      )
    end

    it 'filters by using activesupport Hash modifications' do
      payload = TestBaseSchema.import(foo: 'bar', custom: 1)

      expect(payload).not_to receive(:warn)
      expect(payload.as_json(only: 'foo')).to eq('foo' => 'bar')
    end
  end
end
