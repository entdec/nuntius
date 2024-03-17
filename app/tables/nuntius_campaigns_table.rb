# frozen_string_literal: true

class NuntiusCampaignsTable < ActionTable::ActionTable
  model Nuntius::Campaign

  column(:name)
  column(:metadata) { |campaign| Nuntius.config.metadata_humanize(campaign.metadata) }
  column(:transport)
  column(:state)
  column(:list, sort_field: "nuntius_lists.name") { |campaign| campaign.list.name }

  column :actions, title: "", sortable: false do |campaign|
    next unless campaign.can_publish?

    content_tag(:span, class: "btn-group btn-group-xs") do
      concat link_to(content_tag(:i, nil, class: "fa fa-paper-plane"), nuntius.publish_admin_campaign_path(campaign), data: {turbo_confirm: "Are you sure you want to send out this campaign?", turbo_method: :post}, class: "btn btn-xs btn-danger")
    end
  end

  initial_order :name, :asc

  row_link { |campaign| nuntius.edit_admin_campaign_path(campaign) }

  private

  def scope
    @scope = Nuntius::Campaign.visible
    @scope = Nuntius::Campaign.joins(:list)
  end
end
