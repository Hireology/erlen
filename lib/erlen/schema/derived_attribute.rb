require_relative '../core'
require_relative '../errors'

module Erlen; module Schema
  # This class represents a derived attribute defined in a Schema class. An
  # attribute keeps track of its name, type, and a attribute specific block to
  # derive the value.
  class DerivedAttribute
    # The name of the attribute
    attr_accessor :name

    # The type of the attribute
    attr_accessor :type

    # Attribute specific block to derive value
    attr_accessor :derived_block

    def initialize(name, type, blk)
      self.name = name.to_s
      self.type = type
      self.derived_block = blk # proc object
    end

    # Derives the value using attribute-specific block.
    #
    # @param schema [Object] schema object
    def derive_value(schema)
      derived_block.call(schema)
    end
  end
end; end
