require 'json'
require_relative 'base'

module Erlen; module Serializer
  class JSON < Base
    def self.from_json(json, schema)
      data = ::JSON.parse(json)
      data_to_payload(data, schema)
    end

    def self.to_json(payload)
      data = payload_to_data(payload)
      data.to_json if data
    end
  end
end; end
