class ChangeNuntiusEventsId < ActiveRecord::Migration[8.1]
  def change
    execute "DELETE  FROM public.nuntius_events;"
    add_column :nuntius_events, :uuid, :uuid, default: "gen_random_uuid()", null: false

    change_table :nuntius_events do |t|
      t.remove :id
      t.rename :uuid, :id
    end
    execute "ALTER TABLE nuntius_events ADD PRIMARY KEY (id);"
  end
end
