# frozen_string_literal: true

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

  describe 'any?' do
    it 'returns false if array is empty' do
      payload = TestArraySchema.import_array([])
      expect(payload.any?).to be_falsy
    end

    it 'returns true if array is not empty' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 1, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )
      expect(payload.any?).to be_truthy
    end
  end

  describe '#inject' do
    let(:payload) do
      TestArraySchema.new_array(
        [
          { 'foo' => 'bar', custom: 1 },
          { 'foo' => 'baz', custom: 2 }
        ]
      )
    end

    it 'works with a numeric accumulator' do
      result = payload.inject(0) { |memo, var| memo + var.custom }
      expect(result).to eq(3)
    end

    it 'works with an array accumulator' do
      result = payload.inject([]) { |memo, var| memo << var.foo }
      expect(result).to eq(%w[bar baz])
    end

    it 'is equivalent to reduce' do
      expect(payload.inject(0) { |memo, var| memo + var.custom }).to \
        eq(payload.reduce(0) { |memo, var| memo + var.custom })
    end
  end

  describe '#one?' do
    it 'returns false for an empty array' do
      payload = TestArraySchema.import_array([])

      expect(payload.one?).to be(false)
    end

    it 'returns false if no elements match' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 1, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )

      expect(payload.one? { |item| item.custom == 3 }).to be(false)
    end

    it 'returns true if one element matches' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 1, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )

      expect(payload.one? { |item| item.custom == 2 }).to be(true)
    end

    it 'returns false if more than one element matches' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 2, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )

      expect(payload.one? { |item| item.custom == 2 }).to be(false)
    end
  end

  describe '#none?' do
    it 'returns true for an empty array' do
      payload = TestArraySchema.import_array([])

      expect(payload.none?).to be(true)
    end

    it 'returns false if there are any matches' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 1, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )

      expect(payload.none? { |item| item.custom == 1 }).to be(false)
    end

    it 'returns true if there are no matches' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 1, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )

      expect(payload.none? { |item| item.custom == 3 }).to be(true)
    end
  end

  describe '#all?' do
    it 'returns true for an empty array (vacuously true)' do
      payload = TestArraySchema.import_array([])

      expect(payload.all?).to be(true)
    end

    it 'returns false if not every item matches' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 1, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )

      expect(payload.all? { |item| item.custom == 1 }).to be(false)
    end

    it 'returns false if there are no matches' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 1, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )

      expect(payload.all? { |item| item.custom == 3 }).to be(false)
    end

    it 'returns true if every element matches' do
      payload = TestArraySchema.import_array(
        [
          { 'foo' => 'bar', custom: 1, other: true },
          { 'foo' => 'baz', custom: 2, 'something else' => false }
        ]
      )

      expect(payload.all? { |item| item.custom < 3 }).to be(true)
    end
  end
end

class TestArraySchema < Erlen::Schema::Base
  attribute :foo, String
  attribute :custom, Integer
end
