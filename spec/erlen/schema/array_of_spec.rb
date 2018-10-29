require 'spec_helper'

describe Erlen::Schema::ArrayOf do
  describe 'import' do
    it 'imports hashes into the base schema' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 1, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )

      expect(payload.valid?).to be_truthy
      expect(payload[0].foo).to eq('bar')
      expect(payload[0].custom).to eq(1)
      expect(payload[1].foo).to eq('baz')
      expect(payload[1].custom).to eq(2)
    end
  end

  describe 'new' do
    it 'creates from hashes as expected' do
      payload = TestArraySchema.new_array(
        [
          { 'foo' => 'bar', custom: 1 },
          { 'foo' => 'baz', custom: 2 }
        ]
      )

      expect(payload.valid?).to be_truthy
      expect(payload[0].foo).to eq('bar')
      expect(payload[0].custom).to eq(1)
      expect(payload[1].foo).to eq('baz')
      expect(payload[1].custom).to eq(2)
    end

    it 'strictly interpets hashes' do
      expect do
        TestArraySchema.new_array([{ 'foo' => 'bar', other_value: 'fail' }])
      end.to raise_error(Erlen::NoAttributeError)
    end
  end
end

class TestArraySchema < Erlen::Schema::Base
  attribute :foo, String
  attribute :custom, Integer
end
