class UpdateNuntiusEventsIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :nuntius_events, name: :index_nuntius_events_on_transitionable

    add_index :nuntius_events,
      [:transitionable_type, :transitionable_id, :transition_event],
      name: :index_nuntius_events_on_type_id_event
  end
end
