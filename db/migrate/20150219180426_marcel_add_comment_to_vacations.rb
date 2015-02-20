class MarcelAddCommentToVacations < ActiveRecord::Migration
  def up
    add_column :vacations, :comment, :string, null: false, default: ""
  end

  def down
    remove_column :vacations, :comment
  end
end
