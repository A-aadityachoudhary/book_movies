# app/channels/seating_channel.rb
class SeatingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "seating_channel_showtime_#{params[:showtime_id]}"
  end

  def unsubscribed
    # Cleanup logic
  end

  def toggle_seat(data)
    showtime_seat_id = data['showtime_seat_id']
    user = current_user
    
    ActiveRecord::Base.transaction do
      showtime_seat = ShowtimeSeat.lock("FOR UPDATE").find_by(id: showtime_seat_id)
      return unless showtime_seat

      if data['selected'] == true
        if showtime_seat.truly_available?
          showtime_seat.update!(
            status: :locked,
            locked_by: user,
            locked_at: Time.current
          )
          SeatUnlockJob.set(wait: 5.minutes).perform_later(showtime_seat.id, showtime_seat.locked_at)
          broadcast_seat_status(showtime_seat, "locked", user.id)
        else
          ActionCable.server.broadcast("seating_channel_showtime_#{showtime_seat.showtime_id}", {
            action: "lock_failed",
            showtime_seat_id: showtime_seat.id,
            user_id: user.id
          })
        end
      else
        if showtime_seat.locked? && showtime_seat.locked_by_id == user.id
          showtime_seat.update!(status: :available, locked_by: nil, locked_at: nil)
          broadcast_seat_status(showtime_seat, "available", nil)
        end
      end
    end
  end

  private

  def broadcast_seat_status(seat, status, user_id)
    ActionCable.server.broadcast("seating_channel_showtime_#{seat.showtime_id}", {
      action: "seat_updated",
      showtime_seat_id: seat.id,
      status: status,
      locked_by_id: user_id,
      seat_label: "#{seat.seat.row_name}#{seat.seat.seat_number}"
    })
  end
end