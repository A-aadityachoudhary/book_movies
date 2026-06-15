class CreateShowtimeSeats < ActiveRecord::Migration[8.1]
  def change
    create_table :showtime_seats do |t|
      t.references :showtime, null: false, foreign_key: true
      t.references :seat, null: false, foreign_key: true
      t.integer :status

      t.timestamps
    end
  end
end
