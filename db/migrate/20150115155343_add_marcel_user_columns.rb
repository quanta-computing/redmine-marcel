class AddMarcelUserColumns < ActiveRecord::Migration

  def up
    add_column :users, :paid_vacation_days, :float, null: false, default: 0.0
    add_column :users, :recup_days, :float, null: false, default: 0.0
  end

  def down
    remove_column :users, :paid_vacation_days
    remove_column :users, :recup_days
  end

end
