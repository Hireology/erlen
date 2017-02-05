module Erlen; module Serializer
  class JSONSchema
    include Erlen::Schema

    def self.to_json_schema(erlen_schema_class)
      build_json_schema_object(erlen_schema_class)
    end

    def self.build_base_object(erlen_schema_class)
      {
        type: "object",
        title: erlen_schema_class.name,
        description: "expected structure for #{erlen_schema_class.name}",
        properties: {},
        required: [],
      }
    end

    def self.build_json_schema_object(erlen_schema_class)
      json_schema_object = build_base_object(erlen_schema_class)
      erlen_schema_class.schema_attributes.each_pair do |_, attribute|
        attribute_name = attribute.name.to_sym
        json_schema_object[:properties][attribute_name] = convert_attribute(attribute.type)
        json_schema_object[:required] << attribute_name if attribute.options[:required]
      end

     json_schema_object
    end

    def self.build_json_schema_array(erlen_container_class)
      { type: 'list',
        items: {
          type: convert_attribute(erlen_container_class.element_type),
        }
      }
    end

    def self.convert_attribute(attribute)
      if attribute <= Schema::Base
        convert_container_type(attribute)
      else
        convert_primitive_type(attribute)
      end
    end

    def self.convert_container_type(container_attribute)
      if container_attribute.container_class <= ArrayOf
        build_json_schema_array(container_attribute)
      else
        build_json_schema_object(container_attribute)
      end
    end

    def self.convert_primitive_type(primitive_type)
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
