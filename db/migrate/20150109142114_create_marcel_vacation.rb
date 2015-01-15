class CreateMarcelVacation < ActiveRecord::Migration

  def change
    create_table :vacations do |t|
      t.integer :user_id
      t.integer :activity_id
      t.integer :validator_id, default: nil
      t.datetime :from
      t.datetime :to
    end
  end

end
