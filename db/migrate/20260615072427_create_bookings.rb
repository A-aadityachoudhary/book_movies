class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :showtime, null: false, foreign_key: true
      t.decimal :total_price
      t.integer :status

      t.timestamps
    end
  end
end
