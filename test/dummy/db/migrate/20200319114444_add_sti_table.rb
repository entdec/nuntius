class AddStiTable < ActiveRecord::Migration[6.0]
  def change
    create_table :sti_bases do |t|
      t.string :type
    end
  end
end
