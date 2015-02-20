class MarcelAddGcalIdToVacations < ActiveRecord::Migration
  def up
    add_column :vacations, :gcal_event_id, :string, null: true, default: nil
  end

  def down
    remove_column :vacations, :gcal_event_id
  end
end
