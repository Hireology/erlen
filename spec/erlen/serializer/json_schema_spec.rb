require 'spec_helper'

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

    context 'when converting non-primitive types' do
      it "converts Base schemas to json_schema object structures" do
        class ChildSchema < Erlen::Schema::Base
          attribute :foo, Integer
        end

        class ParentSchema < Erlen::Schema::Base
          attribute :child, ChildSchema
        end

        converted = subject.to_json_schema(ParentSchema)
        expect(converted[:properties]).to eq({
          child: {
            type: "object",
            title: standard_obj_name(ChildSchema),
            description: standard_obj_description(ChildSchema),
            properties: { foo: "integer" },
            required: [],
          }
        })
      end

      it "converts ArrayOf to array json_schema structure - primitive" do
        class ArrayOfTestPrimitiveSchema < Erlen::Schema::Base
          attribute :foo, Erlen::Schema::ArrayOf.new(String)
        end

        converted = subject.to_json_schema(ArrayOfTestPrimitiveSchema)
        expect(converted[:properties]).to eq({
          foo: { "type": "list", items: { "type": "string" } }
        })
      end

      it "converts ArrayOf to array json_schema structure - schema" do
        class ArrayChildSchema < Erlen::Schema::Base
          attribute :foo, Integer
        end

        class ArrayOfTestContainerSchema < Erlen::Schema::Base
          attribute :list, Erlen::Schema::ArrayOf.new(ArrayChildSchema)
        end

        converted = subject.to_json_schema(ArrayOfTestContainerSchema)
        expect(converted[:properties]).to eq({
          list: {
            type: "list",
            items: {
              type: {
                type: "object",
                title: standard_obj_name(ArrayChildSchema),
                description: standard_obj_description(ArrayChildSchema),
                properties: { foo: "integer" },
                required: [],
              }
            }
          }
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

      it "converts Date attribute to 'date'" do
        class DateTestSchema < Erlen::Schema::Base
          attribute :date, Date
        end

        converted = subject.to_json_schema(DateTestSchema)
        expect(converted[:properties]).to eq({ date: "date" })
      end

      it "converts DateTime attribute to 'date'" do
        class DateTimeTestSchema < Erlen::Schema::Base
          attribute :date, DateTime
        end

        converted = subject.to_json_schema(DateTimeTestSchema)
        expect(converted[:properties]).to eq({ date: "date" })
      end

      it "converts Time attribute to 'time'" do
        class TimeTestSchema < Erlen::Schema::Base
          attribute :time, Time
        end

        converted = subject.to_json_schema(TimeTestSchema)
        expect(converted[:properties]).to eq({ time: 'time' })
      end
    end

    context "when converting multi-attribute schemas" do

      it "handles combination of array and object attributes" do
        class MultiAttrChild1 < Erlen::Schema::Base
          attribute :foo, Integer
        end

        class MultiAttrChild2 < Erlen::Schema::Base
          attribute :bar, String, required: true
        end

        class MultiAttr1 < Erlen::Schema::Base
          attribute :primitive, Integer, required: true
          attribute :list, Erlen::Schema::ArrayOf.new(MultiAttrChild1), required: true
          attribute :obj, MultiAttrChild2
        end

        converted = subject.to_json_schema(MultiAttr1)
        expect(converted[:required]).to eq([:primitive, :list])
        expect(converted[:properties][:primitive]).to eq("integer")
        expect(converted[:properties][:list]).to eq({
          type: "list",
          items: {
            type: {
              type: "object",
              title: standard_obj_name(MultiAttrChild1),
              description: standard_obj_description(MultiAttrChild1),
              properties: { foo: "integer" },
              required: [],
            }
          }
        })
        expect(converted[:properties][:obj]).to eq({
          type: "object",
          title: standard_obj_name(MultiAttrChild2),
          description: standard_obj_description(MultiAttrChild2),
          properties: { bar: "string" },
          required: [:bar],
        })
      end
    end
  end

  def standard_obj_name(erlen_class)
    erlen_class.name
  end

  def standard_obj_description(erlen_class)
    "expected structure for #{erlen_class.name}"
  end
end
