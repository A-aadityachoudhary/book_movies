class AddLockingFieldsToShowtimeSeats < ActiveRecord::Migration[8.1]
  def change
    add_column :showtime_seats, :locked_by_id, :integer
    add_column :showtime_seats, :locked_at, :datetime
    add_index :showtime_seats, :locked_by_id
  end
end
