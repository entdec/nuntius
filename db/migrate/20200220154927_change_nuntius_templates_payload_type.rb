# frozen_string_literal: true

class ChangeNuntiusTemplatesPayloadType < ActiveRecord::Migration[5.2]
  def change
    execute "ALTER TABLE nuntius_templates ALTER COLUMN payload TYPE TEXT USING payload::text;"
  end
end
