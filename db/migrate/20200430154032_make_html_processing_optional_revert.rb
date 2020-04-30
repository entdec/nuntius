class MakeHtmlProcessingOptionalRevert < ActiveRecord::Migration[6.0]
  def change
    remove_column :nuntius_templates, :html_inkyrb_processing, :boolean
    remove_column :nuntius_templates, :html_premailer_processing, :boolean
  end
end
