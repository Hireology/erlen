module Erlen; module Converter
  # This class converts an Erlen schema definition into valid JSON Schema format
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

      def serialize_array(array_container)
        json_schema_array = build_base_array
        json_schema_array[:items][:type] = serialize_attribute_type(array_container.element_type)
        json_schema_array
      end

      def serialize_attribute_type(attribute)
        if container?(attribute)
          serialize_container(attribute)
        else
          serialize_primitive(attribute)
        end
      end

      def serialize_container(container_attribute)
        if array_container?(container_attribute)
          serialize_array(container_attribute)
        else
          serialize_object(container_attribute)
        end
      end

      def container?(attribute)
        attribute <= Schema::Base
      end

      def array_container?(attribute)
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

      def build_base_array
        { type: 'array',
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
