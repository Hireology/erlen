module Erlen; module Serializer
  class JSONSchema

    def self.to_json_schema(schema_class)
      base_schema = initialize_schema(schema_class)
      convert_schema(base_schema, schema_class)
    end

    def self.convert_schema(base_schema, schema_class)
      schema_class.schema_attributes.each_pair do |_, attribute|
        attribute_name = attribute.name.to_sym
        base_schema[:properties][attribute_name] = convert_attribute(attribute.type)
        base_schema[:required] << attribute_name if attribute.options[:required]
      end

      base_schema
    end

    def self.convert_attribute(attribute)
      if attribute < Erlen::Schema::Base
        convert_container(attribute)
      else
        convert_type(attribute)
      end
    end

    def self.convert_container(container_attribute)
      if container_attribute.container_class <= ::Erlen::Schema::ArrayOf
        {
          type: 'list',
          items: {
            type: convert_attribute(container_attribute.element_type)
          }
        }
      end
    end

    def self.convert_type(type_attribute)
      if type_attribute == String
        "string"
      elsif type_attribute == Numeric
        "numeric"
      elsif type_attribute == Integer
        "integer"
      elsif type_attribute == Boolean
        "boolean"
      elsif type_attribute == DateTime
        "date"
      else
        "null"
      end
    end

    def self.initialize_schema(schema_class)
      {
        type: "object",
        title: schema_class.name,
        description: "expected structure for #{schema_class.name}",
        properties: {},
        required: []
      }
    end

  end
end; end
