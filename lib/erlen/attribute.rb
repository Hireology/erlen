require_relative 'core'
require_relative 'errors'

module Erlen
  # This class represents an attribute defined in a Schema class. An
  # attribute keeps track of its name, type, additional options, and a
  # attribute specific custom validation.
  class Attribute
    # The name of the attribute
    attr_accessor :name

    # The type of the attribute
    attr_accessor :type

    # Additional options - required, alias
    attr_accessor :options

    # Attribute specific custom validation
    attr_accessor :validation

    def initialize(name, type, options={}, &validation)
      self.name = name.to_s
      self.type = type
      self.options = options
      self.validation = validation # proc object
    end

    # The name of the attribute object. Alias takes the precendence over
    # name.
    #
    # XXX: [david] I'm not so sure about this feature. It is not specific to
    # the schema attribute but rather for importing. I think this feature
    # should be schema specific.
    #
    # @return [String] the alias or name of the attribute
    def obj_attribute_name
      options[:alias] || name
    end

    # Validates the specified value using the attribute-specific validation.
    #
    # @param value [Object] an actual value of the attribute to validate.
    def validate(value)
      if options[:required] && value.is_a?(Undefined)
        raise ValidationError.new("#{name} is required")
      elsif value.is_a?(Undefined) || value.nil?
        # then fine
      elsif type == Boolean
        if (value != true && value != false)
          raise ValidationError.new("#{name}: #{value} is not Boolean")
        end
      elsif type <= BaseSchema && !value.valid?
        # uhh.. this can be better. not tested.
        raise ValidationError.new(value.errors.map {|m| "#{name}: #{m}" }.join("\n"))
      elsif !value.is_a? type
        # TODO: this type check must be revisited. Strict type equality is
        # required for schemas unless allow_subclass is set. Subclassing is
        # allowed for primitive types.
        raise ValidationError.new("#{name}: #{value} is not #{type.name}")
      end

      if !validation.nil? && !validation.call(value)
        raise ValidationError.new("#{name} is not valid")
      end
    end
  end
end
