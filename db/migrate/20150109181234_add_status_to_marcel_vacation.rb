class AddStatusToMarcelVacation < ActiveRecord::Migration
  def self.up
    add_column :vacations, :status, :boolean, null: false, default: 0
  end

  def self.down
    remove_column :vacations, :status
  end
end
