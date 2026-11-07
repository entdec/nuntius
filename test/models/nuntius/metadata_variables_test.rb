# frozen_string_literal: true

require "test_helper"

module Nuntius
  class MetadataVariablesTest < ActiveSupport::TestCase
    test "finds metadata variables, with the record's own value" do
      template = Nuntius::Template.new(metadata: {"logo_url" => "logo.png"})

      variables = MetadataVariables.in(template, "{{ template.metadata.logo_url }} {{campaign.metadata['header']}}", nil, "{{ template.metadata.logo_url }} {{ subscriber.metadata.name }}")

      assert_equal [["template.metadata.logo_url", "logo.png"], ["campaign.metadata.header", nil]], variables
    end
  end
end
