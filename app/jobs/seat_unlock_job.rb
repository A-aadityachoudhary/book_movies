class SeatUnlockJob < ApplicationJob
  queue_as :default

  def perform(showtime_seat_id, lock_timestamp)
    seat = nil
    did_unlock = false

    ActiveRecord::Base.transaction do
      seat = ShowtimeSeat.lock("FOR UPDATE").find_by(id: showtime_seat_id)
      next unless seat
      next unless seat.locked?
      next if seat.locked_at.nil?
      next if seat.locked_at.to_i > lock_timestamp.to_i

      seat.update!(status: :available, locked_by: nil, locked_at: nil)
      did_unlock = true
    end

    if did_unlock && seat
      Rails.logger.info "[SeatUnlockJob] Unlocked seat #{seat.id}, broadcasting available"
      seat.broadcast_status(nil)
    else
      Rails.logger.info "[SeatUnlockJob] Skipped unlock for seat #{showtime_seat_id} — already booked or re-locked"
    end
  end
end