# frozen_string_literal: true

require 'spec_helper'

describe Erlen::Schema::Documentation do
  describe '#to_markdown' do
    it 'looks like markdown' do
      allow(Kernel).to receive(:rand).with(100).and_return(74)
      allow(Kernel).to receive(:rand).with(2).and_return(0)
      expected_doc = <<~END_OF_MARKDOWN
        ## TestDoc

        > Example Response

        ```json

        {
          "int" : 74,
          "less" : {
            "flt" : {},
            "time" : "2018-10-19 08:11:38 -0400",
            "success" : false
          },
          "foos" : [
            "FOOS"
          ]
        }
        ```

        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        int | Integer |  | 
        less | Test Doc Lesser |  | 
        foos | Array of String |  | 

        ## TestDocLesser


        Attributes | Type | Required | Description
        ---------- | ---- | -------- | -----------
        flt | Float | true | 
        time | Time |  | 
        success | Boolean |  | 
      END_OF_MARKDOWN
      expect(TestDocSchema.to_markdown).to eq(expected_doc.chomp)
    end
  end
end

class TestDocLesserSchema < Erlen::Schema::Base
  attribute :flt, Float, required: true
  attribute :time, Time
  attribute :success, Boolean
end

class TestDocSchema < Erlen::Schema::Base
  extend Erlen::Schema::Documentation

  attribute :int, Integer
  attribute :less, TestDocLesserSchema
  attribute :foos, Erlen::Schema::ArrayOf.new(String)
end
