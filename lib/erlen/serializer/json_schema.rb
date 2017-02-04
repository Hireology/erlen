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

    def self.initialize_schema(schema_class)
      {
        type: "object",
        title: schema_class.name,
        description: "expected structure for #{schema_class.name}",
        properties: {},
        required: []
      }
    end

    def self.convert_attribute(attribute)
      if attribute == String
        "string"
      elsif attribute == Numeric
        "numeric"
      elsif attribute == Integer
        "integer"
      elsif attribute == Boolean
        "boolean"
      elsif attribute == DateTime
        "date"
      elsif attribute.type == ::Erlen::Schema::ArrayOf
        {
          "type": "list",
          items: {
            "type": to_json_schema(attribute.element_type)
          }
        }
      else
        "null"
      end
    end
  end
end; end
