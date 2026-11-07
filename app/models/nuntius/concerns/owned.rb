# frozen_string_literal: true

module Nuntius
  module Concerns
    # Records that belong to an account (Nuntius.config.account_class). New
    # records get the current account (Nuntius.config.current_account) unless
    # one is given.
    module Owned
      extend ActiveSupport::Concern

      included do
        belongs_to :account, class_name: Nuntius.config.account_class

        scope :owned_by, ->(accounts) { where(account_id: Array(accounts).map { |account| account.respond_to?(:id) ? account.id : account }) }
        scope :visible, -> { instance_exec(&Nuntius.config.visible_scope) }

        before_validation :assign_current_account, if: :new_record?
      end

      class_methods do
        # The records these associations point at must belong to the same
        # account. A new one, like a list made with its campaign, gets it.
        def validates_same_account(*associations)
          validate do
            associations.each do |association|
              record = public_send(association)
              next unless record

              record.account ||= account if record.new_record?
              errors.add(association, :other_account) if record.account_id != account_id
            end
          end
        end
      end

      private

      def assign_current_account
        self.account ||= Nuntius.config.current_account
      end
    end
  end
end
