require_relative './documentation'

module Erlen; module Schema
  # This class is the basis for all schemas. If a schema class inherits this
  # class, it's ready to define attributes. When a schema class inherits
  # from another schema class, it inherits all the attributes defined by the
  # ancestors.
  #
  # By instantiating this class, you will get a "payload" to/from which you
  # can access attribute data. You may validate the payload using #valid?
  # method.
  #
  # @note Be careful when defining a method inside this class. It must use a
  #       prefix to avoid conflicts with attribute names that may be defined
  #       later by the user.
  class Base
    extend ::Erlen::Schema::Documentation

    # List of error messages
    attr_accessor :errors

    class << self
      # List of schema attribute definitions (pertaining to the class)
      attr_accessor :schema_attributes

      # List of validation procs to run at valid?
      attr_accessor :validator_procs

      # Defines an attribute for the schema. Must specify the type. If
      # validation block is specified, the block will be executed at
      # validation.
      #
      # @param name [Symbol] the name of attribute
      # @param type [Class] it must be either a primitive type or a
      #                     Base class.
      # @param opts [Hash, nil] options
      # @param validation [Proc, nil] optional validation block.
      def attribute(name, type, opts = {}, &validation)
        attr = Attribute.new(name.to_sym, type, opts, &validation)
        schema_attributes[name.to_sym] = attr
      end

      # Defines a collection for the schema. Must specify the type. If
      # validation block is specified, the block will be executed at
      # validation.
      #
      # @param name [Symbol] the name of attribute
      # @param type [Class] class of array elements, it must be either a
      #                     primitive type or a Base class.
      # @param opts [Hash, nil] options
      # @param validation [Proc, nil] optional validation block.
      def collection(name, array_type, opts = {}, &validation)
        attribute(name, ArrayOf.new(array_type), opts, &validation)
      end

      # Defines a custom validation block. Must specify message which is
      # used to identify the validation in case of an error.
      #
      # @param message [String, Symbol] a simple message/name of the
      #                                  validation.
      # @param blk [Proc] the validation code block
      def validate(message, &blk)
        validator_procs << [message, blk]
      end

      # Imports from an object (or a payload). This is different from
      # instantiating the class with a hash or a schema object because it
      # looks for schema attributes from the specified object gracefully.
      #
      # @param obj [Object] any object
      # @return Base the concrete schema object.
      def import(obj, context={})
        payload = new

        schema_attributes.each_pair do |k, attr|
          obj_attribute_name = (attr.options[:alias] || attr.name).to_sym

          if obj.is_a? Hash
            if obj.key?(k)
              attr_val = obj[k]
            elsif obj.key?(k.to_s)
              attr_val = obj[k.to_s]
            elsif obj.key?(obj_attribute_name)
              attr_val = obj[obj_attribute_name]
            elsif obj.key?(obj_attribute_name.to_s)
              attr_val = obj[obj_attribute_name.to_s]
            elsif attr.options.key?(:default)
              attr_val = attr.options[:default]
            else
              attr_val = Undefined.new
            end
          elsif obj.class <= Base # cannot use is_a?
            begin
              attr_val = obj.send(k)
            rescue NoAttributeError => e
              attr_val = attr.options.include?(:default) ? attr.options[:default] : Undefined.new
            end
          elsif obj.respond_to?(obj_attribute_name)
            method = obj.method(obj_attribute_name)

            attr_val = method.arity == 1 ? method.call(context) : method.call
          else
            attr_val = attr.options.include?(:default) ? attr.options[:default] : Undefined.new
          end

          attr_val = attr.type.import(attr_val, context) if attr.type <= Base

          # private method so use send
          payload.send(:__assign_attribute, k, attr_val)
        end

        payload
      end

      # Expects an array of objects and will wrap current class in ArrayOf and
      # return payload.
      #
      # @param obj [Array] array of objects or hashes
      # @param context [Hash] hash of objects providing context for functions
      # @return Base the concrete schema object.
      def import_array(obj_array, context={})
        ArrayOf.new(self).import(obj_array, context)
      end

      # Expects an array of objects and will wrap current class in ArrayOf and
      # return payload. Uses the new function to initialize object so will be more
      # stringent on data requirements.
      #
      # @param obj [Array] array of objects or hashes
      # @param context [Hash] hash of objects providing context for functions
      # @return Base the concrete schema object.
      def new_array(obj_array)
        ArrayOf.new(self).new(obj_array)
      end

      def inherited(klass)
        attrs = schema_attributes.nil? ? {} : schema_attributes.clone
        klass.schema_attributes = attrs
        procs = self.validator_procs.nil? ? [] : self.validator_procs.clone
        klass.validator_procs = procs
      end

      # Determines whether payload is an instance of this schema.
      def schema_of?(payload)
        self == payload.class
      end

    end

    # There are two ways to initialize a payload: (1) by specifying a Hash
    # or (2) by providing an object that may share some of the attribute
    # names. The object (whether it's a hash or payload) doesn't have to
    # have all the attributes defined in the schema. However, it cannot have
    # more attributes than what's defined. Use #import instead to import
    # from a hash or an Object object without this restriction.
    def initialize(obj = {})
      __init_inst_vars

      # TODO: this initialization can be written to be more efficient.
      # Initialize all values to undefined
      self.class.schema_attributes.each_pair do |k, v|
        @attributes[k] = v.options.include?(:default) ? v.options[:default] : Undefined.new
      end

      bad_attributes = []
      if obj.is_a? Hash
        # Bulk assign initial attributes
        obj.each_pair do |k, v|
          if !@attributes.include?(k.to_sym)
            bad_attributes << k
            next
          end

          __assign_attribute(k, v)
        end
      else
        raise ArgumentError
      end

      raise(NoAttributeError, bad_attributes.join(', ')) if bad_attributes.count > 0
    end

    # Checks if a payload is valid or not by validating it against the
    # schema. This check includes type checks, attribute validations, and
    # custom validations.
    #
    # @return [Boolean] true if valid, otherwise false.
    def valid?
      __validate_payload
    end

    # Determine whether the payload was provided the value.
    # This is an effective way to distinguish between an
    # explicitly set nil value and a value that wasn't provided
    #
    # @return [Boolean]
    def attribute_provided?(name)
      __has_attribute(name) &&
        !@attributes[name].is_a?(Erlen::Undefined)
    end

    # Determines if the payload is an instance of the specified schema
    # class. This overrides Object#is_a? so subclassing is not considered
    # true. The logic is actually implemented in ::Base.schema_of?:: method
    # so a concrete schema can implement more precise logic.
    #
    # @param klass [Class] a schema class
    # @return [Boolean] true if payload is considered of the specified type.
    def is_a?(klass)
      klass.schema_of?(self) if klass <= Base
    end

    # Checks if a payload is equal to another by ensuring they are of the
    # same class and contain the same data.
    def ==(other)
      other.is_a?(self.class) && other.to_data == to_data
    end

    # Checks if payloads refer to the same hash key. It is common for
    # classes that override #== to also alias #eql? thusly.
    alias eql? ==

    def method_missing(mname, value=nil)
      if mname.to_s.end_with?('=')
        __assign_attribute(mname[0..-2].to_sym, value)
      else
        __find_attribute_value_by_name(mname.to_sym)
      end
    end

    def respond_to_missing?(mname, include_all = false)
      if mname.to_s.end_with?('=')
        # The lookup is slightly different for assignment
        __has_assignable_attribute(mname[0..-2].to_sym)
      else
        __has_attribute(mname.to_sym)
      end
    end

    # Composes a hash where the keys are attribute names. Any values that
    # are payloads will be flattened to hashes as well.
    #
    # @return [Hash] the payload data
    def to_hash
      warn "[DEPRECATION] `to_hash` is deprecated.  Please use `to_data` instead."
      warn "  #{caller_locations(1).first}"
      to_data
    end

    # Composes a hash where the keys are attribute names. Any values that
    # are payloads will be flattened to hashes as well. Note that keys of
    # undefined values will be excluded in the hash.
    #
    # @return [Hash] the payload data
    def to_data
      arr = []
      self.class.schema_attributes.each do |k, attr|
        val = @attributes[k] # do not use send or __find_attribute_value_by_name
        unless val.is_a?(Undefined)
          val = val.to_data if val.class <= Base
          arr << [attr.name, val]
        end
      end
      Hash[arr]
    end

    def as_json(*args)
      to_data.as_json(*args)
    end

    # Performs a deep cloning of the current payload. It's cloning and not
    # importing so undefined values will remain undefined.
    #
    # @return [Base] a newly cloned payload
    def deep_clone
      self.class.new(to_data)
    end

    protected

    # Initialize all instance variables here so subclasses can use it too.
    def __init_inst_vars
      @attributes = {}
      @errors = []
    end

    def __validate_payload
      @errors.clear
      klass = self.class
      @attributes.each_pair do |k, v|
        klass_attribute = klass.schema_attributes[k]
        begin
          klass_attribute.validate(v)
        rescue ValidationError => e
          @errors << e.message
        end
      end

      klass.validator_procs.each do |m, p|
        begin
          result = p.call(self)
        rescue Exception => e
          @errors << e.message
        else
          @errors << m unless result
        end
      end
      @errors.size == 0
    end

    def __has_assignable_attribute(name)
      @attributes.include?(name)
    end

    def __has_attribute(name)
      !__find_attribute_name(name).nil?
    end

    def __assign_attribute(name, value)
      name = name.to_sym
      raise(NoAttributeError, name) unless __has_assignable_attribute(name)

      # If the attribute type is a schema and value is not yet a schema, then
      # store value as a schema for easy valid check and to hash
      attr = self.class.schema_attributes[name]
      value = attr.type.new(value) if attr.type <= Base && !(value.class <= Base) && !value.nil?

      @attributes[name] = __coerce_type(attr, value)
    end

    def __coerce_type(attr, value)
      case attr.type.to_s
      when 'Integer'
        Integer(value)
      when 'Float'
        Float(value)
      when 'Boolean'
        __parse_bool(value)
      when 'DateTime'
        DateTime.parse(value)
      when 'Date'
        Date.parse(value)
      else
        value
      end
    rescue
      value
    end

    def __parse_bool(value)
      case value
      when 'true', 't', 1
        true
      when 'false', 'f', 0
        false
      else
        value
      end
    end

    def __find_attribute_name(name)
      # If the attribute is include retrieve that, otherwise check for aliases
      return name if @attributes.include?(name)

      attr_pair = self.class.schema_attributes.detect do |_, attr|
        attr.options[:alias] == name
      end

      attr_pair && attr_pair.first
    end

    def __find_attribute_value_by_name(name)
      attrib_name = __find_attribute_name(name)
      raise(NoAttributeError, name) unless attrib_name

      val = @attributes[attrib_name]
      # We don't want to expose Undefined to the outside world, nil it the logical equal
      val.is_a?(Undefined) ? nil : val
    end

  end
end; end
