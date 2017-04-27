module Erlen; module Rails; module Filters
  class CreateSchemaOptionsData

    ACTION_TO_REQUEST_TYPE_MAPPING = {
      show: 'GET',
      index: 'GET',
      create: 'POST',
      update: 'PUT',
      destroy: 'DELETE',
      edit: 'GET',
    }

    def self.run(action, schema)
      option_data = {}
      request_method = ACTION_TO_REQUEST_TYPE_MAPPING[action.to_sym] || 'GET'
      option_data[request_method] = schema.to_json_schema
      option_data
    end

  end
end; end; end
