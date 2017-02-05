# require 'spec_helper'

describe Erlen::Serializer::JSONSchema do
  subject { described_class }

  describe "#to_json_schema" do
    it "builds top level properties" do
      class TopLevelTestSchema < Erlen::Schema::Base; end

      converted = subject.to_json_schema(TopLevelTestSchema)
      expect(converted).to eq({
        type: "object",
        title: "TopLevelTestSchema",
        description: "expected structure for TopLevelTestSchema",
        properties: {},
        required: [],
      })
    end

    context "when translating required option" do
      it "adds attribute name to required array" do
        class RequiredTestSchema < Erlen::Schema::Base
          attribute :foo, String, required: true
        end

        converted = subject.to_json_schema(RequiredTestSchema)
        expect(converted[:properties]).to eq({ foo: "string" })
        expect(converted[:required]).to eq([:foo])
      end

      it "adds multiple attribute names to required array" do
        class RequiredTestSchema < Erlen::Schema::Base
          attribute :foo, String, required: true
          attribute :bar, String
          attribute :baz, String, required: true
        end

        converted = subject.to_json_schema(RequiredTestSchema)
        expect(converted[:properties]).to eq({
          foo: "string",
          bar: "string",
          baz: "string",
        })
        expect(converted[:required]).to eq([:foo, :baz])
      end
    end

    context 'when converting ArrayOf' do
      it "returns correct type info" do
        class ArrayOfTestSchema < Erlen::Schema::Base
          attribute :foo, Erlen::Schema::ArrayOf.new(String)
        end

        converted = subject.to_json_schema(ArrayOfTestSchema)
        expect(converted[:properties]).to eq({
          foo: { "type": "list", items: { "type": "string" } }
        })
      end
    end

    context "when converting basic types" do
      it "converts String attribute to 'string'" do
        class StringTestSchema < Erlen::Schema::Base
          attribute :foo, String
        end

        converted = subject.to_json_schema(StringTestSchema)
        expect(converted[:properties]).to eq({ foo: "string" })
      end

      it "converts Integer attribute to 'integer'" do
        class IntegerTestSchema < Erlen::Schema::Base
          attribute :bar, Integer
        end

        converted = subject.to_json_schema(IntegerTestSchema)
        expect(converted[:properties]).to eq({ bar: "integer" })
      end

      it "converts Numeric attribute to 'numeric'" do
        class NumericTestSchema < Erlen::Schema::Base
          attribute :bax, Numeric
        end

        converted = subject.to_json_schema(NumericTestSchema)
        expect(converted[:properties]).to eq({ bax: "numeric" })
      end

      it "converts Boolean attribute to 'boolean'" do
        class BooleanTestSchema < Erlen::Schema::Base
          attribute :baz, Boolean
        end

        converted = subject.to_json_schema(BooleanTestSchema)
        expect(converted[:properties]).to eq({ baz: "boolean" })
      end

      it "converts DateTime attribute to 'date'" do
        class DateTimeTestSchema < Erlen::Schema::Base
          attribute :date, DateTime
        end

        converted = subject.to_json_schema(DateTimeTestSchema)
        expect(converted[:properties]).to eq({ date: "date" })
      end
    end
  end
end
