module Erlen; module Schema
  # This class dynamically generates a concrete schema class that represents
  # a collection type with a specific element type.
  class ArrayOf
    # List all array methods that are supported out of the box. Some
    # methods are overriden. This list only includes methods that are
    # proxied without any logical change.
    ARRAY_METHODS = [
      :'[]',
      :each,
      :each_with_index,
      :find,
      :index,
      :pop,
      :select
    ]

    # This class method will return a new class that represents a collection
    # schema with the specified element schema. Because of
    # covariance/contravariance issue with a collection type, the element
    # type MUST match in order to be valid. In other words, Floats are not
    # allowed for ArrayOf.new(Integer) because Float != Integer.
    #
    # @param element_type [Class] the type of the elements. This can be
    #                             either a schema or a primitive type.
    # @return [Base] a dynamically created class <= BaseClass
    def self.new(element_type)
      Class.new(Base) do |klass|
        class << klass

          # Specifies the type of the element. For primitive type,
          # subclasses are allowed. For schema type, no subclasses are
          # allowed, even the composite schema types such as AnyOf or
          # ArrayOf.
          attr_accessor :element_type

          def name
            "ArrayOf#{element_type.name}"
          end

          # Imports from an array of objects (or payloads). This is different from
          # instantiating the class with an array hashes or schema objects because it
          # looks for schema attributes from the specified objects gracefully.
          #
          # @param array of objs [Object] any objects
          # @return Base the concrete schema object.
          def import(obj_elements)
            payload = self.new

            if obj_elements.class <= Base
              obj_elements = obj_elements.elements
            elsif obj_elements.class <= Undefined
              obj_elements = []
            end

            obj_elements.each do |obj|
              payload << obj
            end

            payload
          end
        end

        klass.element_type = element_type

        validate("Elements must be #{element_type.name}") do |payload|
          element_type = payload.class.element_type
          # calling a protected method, use `send`.
          payload.send(:elements).find do |e|
            !e.is_a?(element_type) || (element_type <= Base && !e.valid?)
          end.nil?
        end

        # Composes an array where the values are the data equivelant of each element.
        #
        # @return [Hash] the payload data
        def to_hash
          @elements.map do |e|
            self.class.element_type <= BaseSchema ? e.to_hash : e
          end
        end

        def initialize(elements=[])
          @elements = elements.map do |elem|
            normalize_element(elem)
          end
          __init_inst_vars
        end

        def <<(element)
          @elements << normalize_element(element)
        end

        def []=(arg, *more_args)
          # a little cheat - just attempt to normalize.
          more_args.map! { |a| normalize_element(a) }
          @elements.[]=(arg, *more_args)
        end

        # Dynamically create methods that will proxy to elements
        ARRAY_METHODS.each do |mname|
          define_method(mname) do |*args, &blk|
            @elements.send(mname, *args, &blk)
          end
        end

        def is_a?(schema)
          schema <= Base && schema.respond_to?(:element_type) &&
              schema.element_type == self.class.element_type
        end

        protected

        def elements; @elements end

        def normalize_element(element)
          if self.class.element_type <= Base && element.is_a?(Hash)
            self.class.element_type.new(element)
          else
            element
          end
        end

        def proxy(mname, *args, &blk)
          @elements.send(mname, *args, &blk)
        end
      end
    end
  end

  # Just a shortcut for ArrayOf.new
  def self.array_of(element_type)
    ArrayOf.new(element_type)
  end
end; end
