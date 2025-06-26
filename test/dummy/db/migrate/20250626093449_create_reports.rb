class CreateReports < ActiveRecord::Migration[7.0]
  def change
    create_table :reports, id: :uuid do |t|
      t.string :name
      t.string :email
      t.string :state

      t.timestamps
    end
  end
end
