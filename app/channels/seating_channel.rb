class SeatingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "seating_channel_showtime_#{params[:showtime_id]}"
  end

  def unsubscribed
  end

  def toggle_seat(data)
    return unless current_user

    user = current_user
    seat = nil
    action = nil
    lock_failed = false
    showtime_id = nil

    ActiveRecord::Base.transaction do
      seat = ShowtimeSeat.lock("FOR UPDATE").find_by(id: data['showtime_seat_id'])
      next unless seat
      showtime_id = seat.showtime_id

      if data['selected'] == true
        if seat.truly_available?
          seat.update!(status: :locked, locked_by: user, locked_at: Time.current)
          SeatUnlockJob.set(wait: 1.minute).perform_later(seat.id, seat.locked_at)
          action = :locked
        else
          lock_failed = true
        end
      else
        if seat.locked? && seat.locked_by_id == user.id
          seat.update!(status: :available, locked_by: nil, locked_at: nil)
          action = :available
        end
      end
    end

    # All broadcasts happen here — outside the transaction, single source.
    if action == :locked
      seat.broadcast_status(user.id)
    elsif action == :available
      seat.broadcast_status(nil)
    elsif lock_failed && showtime_id
      ActionCable.server.broadcast("seating_channel_showtime_#{showtime_id}", {
        action: "lock_failed",
        showtime_seat_id: data['showtime_seat_id'],
        user_id: user.id
      })
    end
  end
end