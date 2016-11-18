module Erlen
  # This class dynamically generates a concrete schema class that represents
  # a collection type for resources. It adheres to Hireology's API standard.
  class ResourceListSchema
    def self.new(resourceSchema)
      Class.new(Schema::Base) do
        attribute :data, Schema::ArrayOf.new(resourceSchema)
        attribute :page, Integer
        attribute :page_size, Integer
        attribute :count, Integer
      end
    end
  end
end
