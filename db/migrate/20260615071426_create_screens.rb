class CreateScreens < ActiveRecord::Migration[8.1]
  def change
    create_table :screens do |t|
      t.references :theater, null: false, foreign_key: true
      t.integer :screen_number
      t.integer :capacity

      t.timestamps
    end
  end
end
