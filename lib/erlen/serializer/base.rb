module Erlen; module Serializer
  class Base
    def self.hash_to_payload(data, schemaClass)
      data = convert_hash_keys(data)

      schemaClass.new(data)
    end

    def self.payload_to_hash(payload)
      payload_to_data(payload)
    end

    def self.payload_to_data(payload)
      return nil unless payload.valid?

      payload.to_data
    end

    private

    def self.convert_hash_keys(value)
      case value
      when Array
        value.map { |v| convert_hash_keys(v) }
      when Hash
        Hash[value.map { |k, v| [underscore(k.to_s).to_sym, convert_hash_keys(v)] }]
      else
        value
      end
    end

    def self.underscore(str)
      str.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end
end; end
