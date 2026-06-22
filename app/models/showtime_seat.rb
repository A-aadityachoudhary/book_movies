class ShowtimeSeat < ApplicationRecord
  belongs_to :showtime
  belongs_to :seat
  belongs_to :locked_by, class_name: 'User', optional: true

  enum :status, { available: 0, locked: 1, booked: 2 }

  def lock_expired?
    return true if locked_at.nil?
    Time.current > (locked_at + 1.minute)
  end

  def truly_available?
    available? || (locked? && lock_expired?)
  end

  def broadcast_status(locked_by_id_override = locked_by_id)
    ActionCable.server.broadcast("seating_channel_showtime_#{showtime_id}", {
      action: "seat_updated",
      showtime_seat_id: id,
      status: status,
      locked_by_id: locked_by_id_override,
      locked_at: locked_at&.iso8601,  # clients use this to run their own countdown
      seat_label: "#{seat.row_name}#{seat.seat_number}"
    })
  end
end