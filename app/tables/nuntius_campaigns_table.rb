# frozen_string_literal: true

class NuntiusCampaignsTable < ActionTable::ActionTable
  model Nuntius::Campaign

  column(:name)
  column(:metadata) { |campaign| Nuntius.config.metadata_humanize(campaign.metadata) }
  column(:transport)
  column(:state)
  column(:list, sort_field: 'nuntius_lists.name') { |campaign| campaign.list.name }

  initial_order :name, :asc

  row_link { |campaign| nuntius.edit_admin_campaign_path(campaign) }

  private

  def scope
    @scope = Nuntius::Campaign.visible
    @scope = Nuntius::Campaign.joins(:list)
  end
end
