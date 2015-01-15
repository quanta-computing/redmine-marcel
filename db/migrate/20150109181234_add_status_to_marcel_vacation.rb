class AddStatusToMarcelVacation < ActiveRecord::Migration
  def self.up
    add_column :vacations, :status, :boolean, nil: false, default: 0
  end

  def self.down
    remove_column :vacations, :status
  end
end
