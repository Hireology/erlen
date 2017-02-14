module Erlen; module Serializer
  class JSONSchema
    include Erlen::Schema

    def self.to_json_schema(schema)
      serialize_object(schema)
    end

    def self.serialize_object(schema)
      json_schema_object = build_base_object(schema)
      schema.schema_attributes.each_pair do |_, attribute|
        attribute_name = attribute.name.to_sym
        json_schema_object[:properties][attribute_name] = serialize_attribute_type(attribute.type)
        json_schema_object[:required] << attribute_name if attribute.options[:required]
      end

     json_schema_object
    end

    def self.serialize_list(list_collection)
      base_list = build_base_list
      base_list[:items][:type] = serialize_attribute_type(list_collection.element_type)
      base_list
    end

    def self.serialize_attribute_type(attribute)
      if collection?(attribute)
        serialize_collection(attribute)
      else
        serialize_primitive(attribute)
      end
    end

    def self.serialize_collection(collection_attribute)
      if list_collection?(collection_attribute)
        serialize_list(collection_attribute)
      else
        serialize_object(collection_attribute)
      end
    end

    def self.collection?(attribute)
      attribute <= Schema::Base
    end

    def self.list_collection?(attribute)
      attribute&.container_class <= Schema::ArrayOf
    end

    def self.build_base_object(schema)
      {
        type: "object",
        title: schema.name,
        description: "expected structure for #{schema.name}",
        properties: {},
        required: [],
      }
    end

    def self.build_base_list
      { type: 'list',
        items: {
          type: nil,
        }
      }
    end

    def self.serialize_primitive(primitive_type)
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
