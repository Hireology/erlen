module Erlen

  # This class represents empty payload.
  class EmptySchema < BaseSchema
  end

  # This class represents any payload. Any other schema can be a AnySchema
  # instance.
  class AnySchema < BaseSchema
    # AnySchema is always valid.
    #
    # @return [Boolean] true always
    def valid?; true end

    protected

    # Any schema doesn't validate attributes. Just assign!
    def __assign_attribute(k, v)
      @attributes[k] = v
    end
  end

  # A resource payload has at least three pre-defined attributes: id,
  # created_at, and updated_at. Use this to represent a database resource.
  class ResourceSchema < BaseSchema
    attribute :created_at, Time
    attribute :updated_at, Time
    attribute :id, Integer
  end

  # This class dynamically generates a concrete schema class that represents
  # a union type of multiple allowed types.
  class AnyOf
    # This class method will return a new class that is catered to the
    # specified schemas. This schema class represents _any_ of the specified
    # schemas.
    #
    # @param args [Array]
    # @return [BaseSchema] a dynamically created class <= BaseSchema.
    def self.new(*args)
      allowed_schemas = args
      Class.new(BaseSchema) do |klass|
        class << klass
          attr_accessor :allowed_schemas

          def name
            "AnyOf#{self.allowed_schemas.map {|s| s.name}.join("Or")}"
          end

          def import(obj)
            schema = allowed_schemas.find do |s| s.import(obj).valid? end
            payload = schema.import(obj) if schema
            hash = BaseSerializer.payload_to_hash(payload) if payload
            new(hash)
          end
        end

        klass.allowed_schemas = allowed_schemas

        validate("Schema is not validated as an allowed schema") do |payload|
          !payload.send(:__matched_schema_payload).nil?
        end

        def initialize(obj = {})
          @obj = obj # placeholder
          __init_inst_vars
        end

        def is_a?(schema)
          # TODO: Must be transitive. AnyOf(AnyOf(A)) == AnyOf(A), for
          # example.
          super || (self.class.allowed_schemas.any? {|s| s == schema })
        end

        protected

        def __matched_schema_payload
          self.class.allowed_schemas.find do |s|
            s.new(@obj).valid?
          end
        end
      end
    end
  end

  # This class dynamically generates a concrete schema class that represents
  # a collection type with a specific element type.
  class ArrayOf
    # This class method will return a new class that represents a collection
    # schema with the specified element schema. Because of
    # covariance/contravariance issue with a collection type, the element
    # type MUST match in order to be valid. In other words, Floats are not
    # allowed for ArrayOf.new(Integer) because Float != Integer.
    #
    # @param elementSchema [BaseSchema] the schema of the element
    # @return [BaseSchema] a dynamically created class <= BaseClass
    def self.new(elementSchema)
      Class.new(BaseSchema) do |klass|
        class << klass
          attr_accessor :element_schema

          def name
            "ArrayOf#{elementSchema.name}"
          end

          # Imports from an array of objects (or payloads). This is different from
          # instantiating the class with an array hashes or schema objects because it
          # looks for schema attributes from the specified objects gracefully.
          #
          # @param array of objs [Object] any objects
          # @return BaseSchema the concrete schema object.
          def import(obj_elements)
            payload = self.new

            if obj_elements.class <= BaseSchema
              obj_elements = obj_elements.elements
            end

            obj_elements.each do |obj|
              payload.elements << element_schema.import(obj)
            end

            payload
          end
        end

        klass.element_schema = elementSchema

        validate("Elements must be #{elementSchema.name}") do |payload|
          payload.elements.index {|e| !e.is_a?(payload.class.element_schema) || !e.valid? }.nil?
        end

        # Composes an array where the values are the data equivelant of each element.
        #
        # @return [Hash] the payload data
        def to_hash
          @elements.map {|e| e.to_hash }
        end

        def initialize(elements=[])
          @elements = elements.map do |elem|
            if self.class.element_schema <= BaseSchema
              self.class.element_schema.new(elem)
            else
              elem
            end
          end
          __init_inst_vars
        end

        # Allows elements to be accessible as a special attribute.
        #
        # @return [Array] an array of payload (must be a specific schema)
        def elements
          @valid = nil # hacky
          @elements
        end

        def is_a?(schema)
          schema <= BaseSchema && schema.respond_to?(:element_schema) &&
              schema.element_schema == self.class.element_schema
        end
      end
    end
  end

  # This class dynamically generates a concrete schema class that represents
  # a collection type for resources. It adheres to Hireology's API standard.
  class ResourceListSchema
    def self.new(resourceSchema)
      Class.new(BaseSchema) do
        attribute :data, ArrayOf.new(resourceSchema)
        attribute :page, Integer
        attribute :page_size, Integer
        attribute :count, Integer
      end
    end
  end

end

