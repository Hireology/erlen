# frozen_string_literal: true

require 'spec_helper'

describe Erlen::Schema::Documentation do
  describe '#to_markdown' do
    it 'documents an Integer field' do
      allow(TestDocIntegerSchema).to receive(:rand).with(100).and_return(74)
      expected_markdown = <<~END_OF_MARKDOWN
        ## TestDocInteger

        > Example Response

        ```json

        {
          "int" : 74
        }
        ```

        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        int | Integer |  | 
      END_OF_MARKDOWN

      expect(TestDocIntegerSchema.to_markdown).to eq(expected_markdown.chomp)
    end

    it 'documents a String attirbute' do
      expected_markdown = <<~END_OF_MARKDOWN
        ## TestDocString

        > Example Response

        ```json

        {
          "foo" : "FOO"
        }
        ```

        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        foo | String |  | 
      END_OF_MARKDOWN

      expect(TestDocStringSchema.to_markdown).to eq(expected_markdown.chomp)
    end

    it 'documents a Time attribute' do
      allow(Time).to receive(:now).and_return(
        Time.new(2018, 10, 19, 10, 12, 37, 0)
      )
      expected_markdown = <<~END_OF_MARKDOWN
        ## TestDocTime

        > Example Response

        ```json

        {
          "time" : "2018-10-19 10:12:37 +0000"
        }
        ```

        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        time | Time |  | 
      END_OF_MARKDOWN

      expect(TestDocTimeSchema.to_markdown).to eq(expected_markdown.chomp)
    end

    it 'documents a Boolean attribute' do
      allow(TestDocBooleanSchema).to receive(:rand).with(2).and_return(0)
      expected_markdown = <<~END_OF_MARKDOWN
        ## TestDocBoolean

        > Example Response

        ```json

        {
          "success" : false
        }
        ```

        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        success | Boolean |  | 
      END_OF_MARKDOWN

      expect(TestDocBooleanSchema.to_markdown).to eq(expected_markdown.chomp)
    end

    it 'documents an ArrayOf attribute' do
      expected_markdown = <<~END_OF_MARKDOWN
        ## TestDocArrayOf

        > Example Response

        ```json

        {
          "foos" : [
            "FOOS"
          ]
        }
        ```

        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        foos | Array of String |  | 
      END_OF_MARKDOWN

      expect(TestDocArrayOfSchema.to_markdown).to eq(expected_markdown.chomp)
    end

    it 'documents a Schema attribute' do
      allow(TestDocComposedSchema).to receive(:rand).with(100).and_return(42)
      expected_markdown = <<~END_OF_MARKDOWN
        ## TestDocComposed

        > Example Response

        ```json

        {
          "less" : {
            "id" : 42
          }
        }
        ```

        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        less | Test Doc Lesser |  | 

        ## TestDocLesser


        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        id | Integer | true | 
      END_OF_MARKDOWN

      expect(TestDocComposedSchema.to_markdown).to eq(expected_markdown.chomp)
    end

    it 'documents unknown types' do
      expected_markdown = <<~END_OF_MARKDOWN
        ## TestDocUnknown

        > Example Response

        ```json

        {
          "unknown_type" : {}
        }
        ```

        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        unknown_type | Float |  | 
      END_OF_MARKDOWN

      expect(TestDocUnknownSchema.to_markdown).to eq(expected_markdown.chomp)
    end
  end
end

class TestDocIntegerSchema < Erlen::Schema::Base
  extend Erlen::Schema::Documentation
  attribute :int, Integer
end

class TestDocStringSchema < Erlen::Schema::Base
  extend Erlen::Schema::Documentation
  attribute :foo, String
end

class TestDocTimeSchema < Erlen::Schema::Base
  extend Erlen::Schema::Documentation
  attribute :time, Time
end

class TestDocBooleanSchema < Erlen::Schema::Base
  extend Erlen::Schema::Documentation
  attribute :success, Boolean
end

class TestDocArrayOfSchema < Erlen::Schema::Base
  extend Erlen::Schema::Documentation
  attribute :foos, Erlen::Schema::ArrayOf.new(String)
end

class TestDocLesserSchema < Erlen::Schema::Base
  attribute :id, Integer, required: true
end

class TestDocComposedSchema < Erlen::Schema::Base
  extend Erlen::Schema::Documentation
  attribute :less, TestDocLesserSchema
end

class TestDocUnknownSchema < Erlen::Schema::Base
  extend Erlen::Schema::Documentation
  attribute :unknown_type, Float
end
