# frozen_string_literal: true

module Nuntius
  class SubscribersTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Subscriber

      column(:list_id) do
        internal true
        filter
      end

      column :first_name do
        internal true
      end
      column :last_name do
        internal true
      end
      column :nuntiable_type do
        internal true # Needed for related_object below
      end
      column :nuntiable_id do
        internal true # Needed for related_object below
      end
      column(:name) do
        render do
          html do |subscriber|
            subscriber.name
          end
        end
      end
      column(:email)
      column(:phone_number)
      column(:unsubscribed_at)
      column(:tags) do
        render do
          html do |subscriber|
            subscriber.tags&.join(",")
          end
        end
      end

      column(:object) do # do |message|
        render do
          html do |message|
            if message.nuntiable
              link_to "#{message.nuntiable} (#{message.nuntiable_type})", begin
                url_for(message.nuntiable)
              rescue
                ""
              end
            end
          end
        end
      end

      link { |subscriber| nuntius.edit_admin_list_subscriber_path(subscriber, list_id: subscriber.list) }
    end

    private

    def scope
      @scope = Nuntius::Subscriber.all
      @scope = @scope.where(list_id: params[:list_id]) if params[:list_id].present?
      @scope
    end
  end
end
