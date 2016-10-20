module Erlen

  # just listing out frequently used schemas as base schemas

  class BaseTimestampSchema < BaseSchema
    attribute :created_at, Time
    attribute :updated_at, Time
  end

  class BaseIDSchema < BaseTimestampSchema
    attribute :id, Integer
  end

  class ListSchema < BaseSchema
    attribute :data, Array
    attribute :page, Integer
    attribute :page_size, Integer
    attribute :count, Integer
  end

end

