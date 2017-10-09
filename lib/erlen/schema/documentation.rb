module Erlen; module Schema
  module Documentation
    #
    #
    #
    # @return a string in markdown representing the schema
    def to_markdown
      name = self.name.demodulize.gsub('Schema', '')
      result = ["## #{name}", '', '> Example Response', '', '```json', '']

      # JSON EXAMPLE
      result.concat(example_value(self))

      result << '```'

      result.concat(class_attributes(self))
      result.join("\n")
    end

    def example_value(schema_klass, indentation=2)
      result = []
      result << '{'

      attr_count = 1
      total_count = schema_klass.schema_attributes.count
      schema_klass.schema_attributes.each do |attr_name, attr|
        comma = attr_count == total_count ? '' : ','
        result << "#{' ' * indentation}\"#{attr_name}\" : #{example_attr_value(attr.type, attr.name, indentation)}#{comma}"
        attr_count += 1
      end

      result << "#{' ' * (indentation - 2)}}"
      result
    end

    def example_attr_value(attr_type, attr_name, indentation)
      if attr_type == Integer
        rand(100)
      elsif attr_type == String
        "\"#{attr_name.titleize.upcase}\""
      elsif [Time, Date].include? attr_type
        "\"#{Time.current}\""
      elsif attr_type == Boolean
        rand(2) == 1
      elsif attr_type < Base && attr_type.respond_to?(:element_type)
        val = example_attr_value(attr_type.element_type, attr_name, indentation + 2)
        [
          '[',
          "#{' ' * (indentation + 2)}#{val}",
          "#{' ' * indentation}]"
        ].join("\n")
      elsif attr_type < Base
        example_value(attr_type, indentation + 2).join("\n")
      else
        {}
      end
    end

    def class_attributes(klass)
      types = []
      result = [
        '',
        'Attributes | Type | Required | Description',
        '---------- | ---- | -------- | -----------'
      ]

      klass.schema_attributes.each do |attr_name, attr|
        if attr.type.respond_to?(:element_type)
          type_name = attr.type.element_type.name.demodulize.gsub('Schema', '').titleize
          result << "#{attr_name} | Array of #{type_name} | #{attr.options[:required]} | "
          types << attr.type.element_type if (attr.type.element_type < Base)
        elsif attr.type < Base
          type_name = attr.type.name.demodulize.gsub('Schema', '').titleize
          result << "#{attr_name} | #{type_name} | #{attr.options[:required]} | "
          types << attr.type
        else
          result << "#{attr_name} | #{attr.type} | #{attr.options[:required]} | "
        end
      end

      types.each do |t|
        result << ''
        result << "## #{t.name.demodulize.gsub('Schema', '')}"
        result << ''

        result.concat(class_attributes(t))
      end

      result
    end
  end
end; end
