class AddConvertedFromToNuntiusTemplates < ActiveRecord::Migration[7.1]
  def change
    # What a template was before it was converted to the email editor: its old
    # layout and body (Nuntius::TemplateConversion)
    add_column :nuntius_templates, :converted_from, :jsonb
  end
end
