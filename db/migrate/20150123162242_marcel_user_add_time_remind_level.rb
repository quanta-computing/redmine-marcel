class MarcelUserAddTimeRemindLevel < ActiveRecord::Migration
  def up
    add_column :users, :time_remind_level, :integer, null: false, default: 0
  end

  def down
    remove_column :users, :time_remind_level
  end
end
