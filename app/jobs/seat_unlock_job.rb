class SeatUnlockJob < ApplicationJob
  queue_as :default

  def perform(showtime_seat_id, lock_timestamp)
    seat = ShowtimeSeat.find_by(id: showtime_seat_id)
    return unless seat
    
    # Verify the seat is still locked and that a newer lock hasn't overwritten it
    if seat.locked? && seat.locked_at.to_i == lock_timestamp.to_i
      seat.update!(status: :available, locked_by: nil, locked_at: nil)
      
      # Broadcast the eviction cleanup to anyone looking at the map page
      ActionCable.server.broadcast("seating_channel_showtime_#{seat.showtime_id}", {
        action: "seat_updated",
        showtime_seat_id: seat.id,
        status: "available",
        locked_by_id: nil
      })
    end
  end
end