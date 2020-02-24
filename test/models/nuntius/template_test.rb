# frozen_string_literal: true

require 'test_helper'

module Nuntius
  class TemplateTest < ActiveSupport::TestCase
    test 'translation scope' do
      t = Template.new(transport: 'slack', klass: 'Cow', event: 'moo')
      assert_equal 'cow.moo.slack', t.translation_scope
    end
  end
end
