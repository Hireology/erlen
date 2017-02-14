module Erlen; module Serializer
  class JSONSchema
    include Erlen::Schema

    def self.to_json_schema(erlen_schema)
      build_json_schema_object(erlen_schema)
    end

    def self.build_json_schema_object(erlen_schema)
      json_schema_object = build_base_object(erlen_schema)
      erlen_schema.schema_attributes.each_pair do |_, attribute|
        attribute_name = attribute.name.to_sym
        json_schema_object[:properties][attribute_name] = convert_attribute(attribute.type)
        json_schema_object[:required] << attribute_name if attribute.options[:required]
      end

     json_schema_object
    end

    def self.build_base_object(erlen_schema)
      {
        type: "object",
        title: erlen_schema.name,
        description: "expected structure for #{erlen_schema.name}",
        properties: {},
        required: [],
      }
    end

    def self.build_json_schema_array(erlen_container)
      { type: 'list',
        items: {
          type: convert_attribute(erlen_container.element_type),
        }
      }
    end

    def self.convert_attribute(attribute)
      if attribute <= Schema::Base
        convert_collection(attribute)
      else
        convert_primitive(attribute)
      end
    end

    def self.convert_collection(collection_attribute)
      if collection_attribute.container_class <= ArrayOf
        build_json_schema_array(collection_attribute)
      else
        build_json_schema_object(collection_attribute)
      end
    end

    def self.convert_primitive(primitive_type)
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
end; end
