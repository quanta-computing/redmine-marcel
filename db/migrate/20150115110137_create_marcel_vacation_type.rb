class CreateMarcelVacationType < ActiveRecord::Migration
  def up
    create_table :vacation_types do |t|
      t.string :name, nil: false
      t.boolean :use_paid_vacation_days, nil: false, default: 0
      t.boolean :use_recup_days, nil: false, default: 0
      t.boolean :use_eating_tickets, nil: false, default: 0

    end
  end

  def down
    drop_table :vacation_types
  end
end
