class AddTimebasedLimitToNuntiusTemplates < ActiveRecord::Migration[8.1]
  def change
    # At most this many messages a run (nil: config.timebased_limit)
    add_column :nuntius_templates, :timebased_limit, :integer
  end
end
