module Erlen; module Schema
  # This class dynamically generates a concrete schema *class* that
  # represents a collection type with a specific element type. The payload
  # of this schema works similar to Array object.
  #
  # Refer to the constants defined in the class to see which Array methods
  # are supported. Generally, the following features are NOT supported: any
  # range parameters, start-end parameters, permutations, and
  # multi-dimensional operation.
  #
  class ArrayOf

    # List of methods that we simply proxy
    METHODS_TO_PROXY = [
      :[],
      :any,
      :at,
      :bsearch,
      :count,
      :cycle,
      :delete,
      :delete_at,
      :empty?,
      :find,
      :fetch,
      :find_index,
      :include?,
      :index,
      :inspect,
      :join,
      :length,
      :rindex,
      :slice,
      :to_a,
      :to_ary
    ]

    # List of methods that we simply proxy but return self
    METHODS_TO_PROXY_AND_RETURN_SELF = [
      :clear,
      :collect!,
      :compact!,
      :concat,
      :delete_if,
      :each,
      :each_index,
      :each_with_index,
      :fill,
      :initialize_copy,
      :insert,
      :keep_if,
      :length,
      :map!,
      :reject!,
      :replace,
      :reverse!,
      :reverse_each,
      :rotate!,
      :select!,
      :size,
      :sort!,
      :sort_by!,
      :uniq!,
      :unshift
    ]

    # List of methods that we proxy but return the result in a new ArrayOf
    # payload.
    METHODS_TO_PROXY_AND_RETURN_NEW = [
      :collect,
      :compact,
      :drop,
      :drop_while,
      :map,
      :reject,
      :reverse,
      :rotate,
      :select,
      :shuffle,
      :sort,
      :take,
      :take_while,
      :uniq,
      :values_at
    ]

    # List of binary operation methods that we proxy but also check if the
    # operand is an ArrayOf payload (and strip the payload when proxing).
    METHODS_TO_PROXY_BINARY_OP = [
      :<=>,
      :==
    ]

    # List of binary operation methods that we proxy and return self. It
    # also checks if the operand is an ArrayOf payload (and strip the
    # payload when proxing).
    METHODS_TO_PROXY_BINARY_OP_AND_RETURN_NEW = [
      :&,
      :+,
      :-,
    ]

    # Any method not listed here may have been written out. See instance
    # methods defined below.

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

          # For better debugging
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

            if obj_elements.class <= Base && obj_elements.class.respond_to?(:element_type)
              obj_elements = obj_elements.send(:elements)
            elsif obj_elements.nil? || obj_elements.is_a?(Undefined)
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
          warn "[DEPRECATION] `to_hash` is deprecated.  Please use `to_data` instead."
          to_data
        end

        # Composes an array where the values are the data equivelant of each element.
        #
        # @return [Array] the payload data
        def to_data
          @elements.map do |e|
            self.class.element_type <= Base ? e.to_data : e
          end
        end

        def initialize(elements=[])
          @elements = elements.map { |elem| normalize_element(elem) }
          __init_inst_vars
        end

        def *(arg)
          result = @elements * arg
          if result.is_a? String
            result
          else
            self.class.new(result)
          end
        end

        # Must normalize before assinging element
        def <<(element)
          @elements << normalize_element(element)
          self
        end

        # No range option
        def []=(arg, *more_args)
          more_args.map! { |a| normalize_element(a) }
          @elements.[]=(arg, *more_args)
        end

        def first(n=nil)
          return @elements.first if n.nil?
          self.class.new(@elements.first(n))
        end

        def last(n=nil)
          return @elements.last if n.nil?
          self.class.new(@elements.last(n))
        end

        def pop(n=nil)
          return @elements.pop if n.nil?
          self.class.new(@elements.pop(n))
        end

        # Must normalize before assinging element, so use <<
        def push(*args)
          args.each { |arg| self << arg }
          self
        end

        def shift(n=nil)
          return @elements.shift if n.nil?
          self.class.new(@elements.shift(n))
        end

        def is_a?(schema)
          schema <= Base && schema.respond_to?(:element_type) &&
              schema.element_type == self.class.element_type
        end

        # Dynamically create methods that will proxy to elements
        METHODS_TO_PROXY.each do |mname|
          define_method(mname) do |*args, &blk|
            @elements.send(mname, *args, &blk)
          end
        end

        METHODS_TO_PROXY_AND_RETURN_SELF.each do |mname|
          define_method(mname) do |*args, &blk|
            @elements.send(mname, *args, &blk)
            self
          end
        end

        METHODS_TO_PROXY_AND_RETURN_NEW.each do |mname|
          define_method(mname) do |*args, &blk|
            self.class.new(@elements.send(mname, *args, &blk))
          end
        end

        METHODS_TO_PROXY_BINARY_OP.each do |mname|
          define_method(mname) do |other, &blk|
            raise InvalidPayloadError unless other.is_a?(self.class)
            @elements.send(mname, other.send(:elements), &blk)
          end
        end

        METHODS_TO_PROXY_BINARY_OP_AND_RETURN_NEW.each do |mname|
          define_method(mname) do |other, &blk|
            raise InvalidPayloadError unless other.is_a?(self.class)
            self.class.new(@elements.send(mname, other.send(:elements), &blk))
          end
        end

        protected

        def elements; @elements end

        def normalize_element(element)
          if self.class.element_type <= Base && element.is_a?(Hash)
            self.class.element_type.new(element)

          elsif self.class.element_type <= Base
            self.class.element_type.import(element)

          else
            element
          end
        end
      end
    end
  end

  # Just a shortcut for ArrayOf.new
  def self.array_of(element_type)
    ArrayOf.new(element_type)
  end
end; end
