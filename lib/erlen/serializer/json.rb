require 'json'
require_relative 'base'

module Erlen; module Serializer
  class JSON < Base
    def self.from_json(json, schemaClass)
      data = ::JSON.parse(json)

      hash_to_payload(data, schemaClass)
    end

    def self.to_json(payload)
      data = payload_to_data(payload)
      data.to_json if data
    end
  end
end; end
