class AddSourceToNuntiusMessages < ActiveRecord::Migration[8.1]
  def change
    # What sent it, when something did besides its template's event (Template#deliver_to's source:): an app's
    # automation run, a mailing of a selection. Its object, what it's about, stays its nuntiable.
    add_reference :nuntius_messages, :source, polymorphic: true, type: :uuid, index: true
  end
end
