require 'spec_helper'

describe Erlen::Schema::DerivedAttribute do
  subject { described_class }

  describe '#initialize' do
    it 'sets all the values' do
      schema = DerivedSchema.new({})
      attr = subject.new(:full_name, Type, proc do |s|
        "#{s.first_name} #{s.last_name}"
      end)

      expect(attr.name).to eq('full_name')
      expect(attr.type).to eq(Type)
      expect(attr.derived_block.call(schema)).to eq('foo bar')
    end
  end

  describe '#derive_value' do
    it 'runs block to generate derived value' do
      schema = DerivedSchema.new({})
      attr = subject.new(:derived_attr, Type, proc do |s|
        "#{s.first_name} #{s.last_name}"
      end)

      expect(attr.derive_value(schema)).to eq('foo bar')
    end
  end
end

class Type; end

class DerivedSchema < Erlen::Schema::Base
  attribute :first_name, String, default: 'foo'
  attribute :last_name, String, default: 'bar'
end
