module Erlen; module Serializer
  # This class translates an Erlen schema definition into valid JSON Schema format
  # More information about the JSON schema format can be found here: http://json-schema.org/
  class JSONSchema
    include Erlen::Schema

    # @param schema [Schema] an Erlen Schema definition
    # @return [JsonSchema] a representation of the Erlen Schema in JSON Schema format
    def self.to_json_schema(schema)
      serialize_object(schema)
    end

    class << self

      private

      def serialize_object(schema)
        json_schema_object = build_base_object(schema)
        schema.schema_attributes.each_pair do |_, attribute|
          attribute_name = attribute.name.to_sym
          json_schema_object[:properties][attribute_name] = serialize_attribute_type(attribute.type)
          json_schema_object[:required] << attribute_name if attribute.options[:required]
        end

        json_schema_object
      end

      def serialize_list(list_collection)
        json_schema_list = build_base_list
        json_schema_list[:items][:type] = serialize_attribute_type(list_collection.element_type)
        json_schema_list
      end

      def serialize_attribute_type(attribute)
        if collection?(attribute)
          serialize_collection(attribute)
        else
          serialize_primitive(attribute)
        end
      end

      def serialize_collection(collection_attribute)
        if list_collection?(collection_attribute)
          serialize_list(collection_attribute)
        else
          serialize_object(collection_attribute)
        end
      end

      def collection?(attribute)
        attribute <= Schema::Base
      end

      def list_collection?(attribute)
        attribute <= Schema::ArrayBase
      end

      def build_base_object(schema)
        {
          type: "object",
          title: schema.name,
          description: "expected structure for #{schema.name}",
          properties: {},
          required: [],
        }
      end

      def build_base_list
        { type: 'list',
          items: {
          type: nil,
        }
        }
      end

      def serialize_primitive(primitive_type)
        case
        when primitive_type <= String
          "string"
        when primitive_type <= Integer
          "integer"
        when primitive_type <= Numeric
          "numeric"
        when primitive_type <= Boolean
          "boolean"
        when primitive_type <= Date
          "date"
        when primitive_type <= Time
          "time"
        else
          nil
        end
      end
    end
  end
end; end
