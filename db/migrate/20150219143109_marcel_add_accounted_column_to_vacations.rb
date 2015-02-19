class MarcelAddAccountedColumnToVacations < ActiveRecord::Migration
  def up
    add_column :vacations, :accounted, :bool, null: false, default: false
  end

  def down
    remove_column :vacations, :accounted
  end
end
