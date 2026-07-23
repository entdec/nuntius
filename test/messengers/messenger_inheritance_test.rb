# frozen_string_literal: true

require "test_helper"

module Nuntius
  class MessengerInheritanceTest < ActiveSupport::TestCase
    class ScopedParentMessenger < Nuntius::BaseMessenger
      locale ->(_object) { :nl }
      template_scope ->(_object) { where(enabled: true) }
    end

    class InheritingChildMessenger < ScopedParentMessenger
    end

    test "subclass inherits locale from its parent messenger" do
      assert_equal ScopedParentMessenger.locale, InheritingChildMessenger.locale
      assert_not_nil InheritingChildMessenger.locale
    end

    test "subclass inherits template_scope from its parent messenger" do
      assert_equal ScopedParentMessenger.template_scope, InheritingChildMessenger.template_scope
      assert_not_nil InheritingChildMessenger.template_scope
    end

    test "overriding template_scope on a subclass does not mutate the parent" do
      overriding = Class.new(ScopedParentMessenger)
      own_scope = ->(_object) { none }
      overriding.template_scope(own_scope)

      assert_equal own_scope, overriding.template_scope
      refute_equal own_scope, ScopedParentMessenger.template_scope
    end
  end
end
