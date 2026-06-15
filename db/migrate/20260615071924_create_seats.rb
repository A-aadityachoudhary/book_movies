class CreateSeats < ActiveRecord::Migration[8.1]
  def change
    create_table :seats do |t|
      t.references :screen, null: false, foreign_key: true
      t.string :row_name
      t.integer :seat_number

      t.timestamps
    end
  end
end
