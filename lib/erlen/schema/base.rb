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
      # @param validation [Proc, nil] optinal validation block.
      def attribute(name, type, opts={}, &validation)
        attr = Attribute.new(name.to_sym, type, opts, &validation)
        schema_attributes[name.to_sym] = attr
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
      def import(obj)
        payload = self.new

        schema_attributes.each_pair do |k, attr|
          obj_attribute_name = (attr.options[:alias] || attr.name).to_sym

          if obj.is_a? Hash
            attr_val = obj[k]
          elsif obj.class <= Base # cannot use is_a?
            begin
              attr_val = obj.send(k)
            rescue NoAttributeError => e
              attr_val = attr.options.include?(:default) ? attr.options[:default] : Undefined.new
            end
          elsif obj.respond_to?(obj_attribute_name)
            attr_val = obj.send(obj_attribute_name)
          else
            attr_val = attr.options.include?(:default) ? attr.options[:default] : Undefined.new
          end

          attr_val = attr.type.import(attr_val) if attr.type <= Base

          # private method so use send
          payload.send(:__assign_attribute, k, attr_val)
        end

        payload
      end

      def inherited(klass)
        attrs = schema_attributes.nil? ? {} : schema_attributes.clone
        klass.schema_attributes = attrs
        procs = self.validator_procs.nil? ? [] : self.validator_procs.clone
        klass.validator_procs = procs
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

      if obj.is_a? Hash
        # Bulk assign initial attributes
        obj.each_pair do |k, v|
          __assign_attribute(k, v)
        end
      else
        raise ArgumentError
      end
    end

    # Checks if a payload is valid or not by validating it against the
    # schema. This check includes type checks, attribute validations, and
    # custom validations.
    #
    # @return [Boolean] true if valid, otherwise false.
    def valid?
      __validate_payload
    end

    # Determines if the payload is an instance of the specified schema
    # class. This overrides Object#is_a? so subclassing is not considered
    # true.
    #
    # TODO: we may have to dig more into how is_a? is really implemented.
    #
    # @param klass [Class] a schema class
    # @return [Boolean] true if payload is considered of the specified type.
    def is_a?(klass)
      klass == self.class
    end

    def method_missing(mname, value=nil)
      if mname.to_s.end_with?('=')
        __assign_attribute(mname[0..-2].to_sym, value)
      else
        __find_attribute_value_by_name(mname.to_sym)
      end
    end

    # Composes a hash where the keys are attribute names. Any values that
    # are payloads will be flattened to hashes as well.
    #
    # @return [Hash] the payload data
    def to_hash
      attrs = self.class.schema_attributes

      hash = attrs.map do |k, attr|
        val = send(k)
        val = val.to_hash if val.class <= Base

        [attr.name, val]
      end

      Hash[hash]
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

    def __assign_attribute(name, value)
      name = name.to_sym
      raise(NoAttributeError, name) unless @attributes.include?(name)

      # If the attribute type is a schema and value is not yet a schema, then
      # store value as a schema for easy valid check and to hash
      attr = self.class.schema_attributes[name]
      value = attr.type.new(value) if attr.type <= Base && !(value.class <= Base)

      @attributes[name] = value
    end

    def __find_attribute_value_by_name(name)
      # If the attribute is include retrieve that, otherwise check for aliases
      if @attributes.include?(name)
        val = @attributes[name]

        # We don't want to expose Undefined to the outside world, nil it the logical equal
        return val.is_a?(Undefined) ? nil : val
      else
        self.class.schema_attributes.each_pair do |k, attr|
          return @attributes[k] if attr.options[:alias] == name
        end
      end

      raise NoAttributeError, name
    end

  end
end; end
