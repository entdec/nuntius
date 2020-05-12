class MakeHtmlProcessingOptional < ActiveRecord::Migration[5.2]
  def change
    add_column :nuntius_templates, :html_inkyrb_processing, :boolean, default: true, null: false
    add_column :nuntius_templates, :html_premailer_processing, :boolean, default: true, null: false
  end
end
