class BookingsController < ApplicationController
  # Ensure user authentication before parsing resource objects
  before_action :authenticate_user!
  
  # CanCanCan hooks into ability.rb to automate loading, scoping, and authorization
  load_and_authorize_resource

  # URL: GET /bookings
  def index
    # REFACTOR: Removed manual current_user.admin? checking branches.
    # CanCanCan's @bookings variable is already automatically scoped:
    # Admins see all rows, while Customers only see their own rows.
    @bookings = @bookings.includes(:user, showtime: :movie).order(created_at: :desc)
  end

  # URL: POST /bookings
  def create
    @showtime = Showtime.find(params[:showtime_id])
    selected_seat_ids = params[:seat_ids] 

    if selected_seat_ids.blank?
      redirect_to @showtime, alert: "Please select at least one seat before booking."
      return
    end

    # Track validation status outside of the transaction scope block wrapper
    booking_successful = false

    # Database Row-Level Locking Sequence
    ActiveRecord::Base.transaction do
      # 1. Fetch seats and lock them to prevent race conditions
      seats = ShowtimeSeat.where(id: selected_seat_ids).lock("FOR UPDATE")

      # 2. Safety Check: Verify availability status
      if seats.all? { |s| s.available? || (s.locked? && s.locked_by_id == current_user.id) }
        
        # 3. CanCanCan already initialized @booking, we populate its attributes safely
        @booking.user = current_user
        @booking.showtime = @showtime
        @booking.total_price = seats.size * @showtime.price
        @booking.status = :pending
        @booking.save!

        # 4. Update individual layout seats and generate associated ticket line items
        seats.each do |seat|
          seat.update!(status: :booked, locked_by: nil, locked_at: nil)
          seat.broadcast_status(nil)
          Ticket.create!(booking: @booking, showtime_seat: seat)
        end

        booking_successful = true
      else
        # Force a database rollback if a seat was snatched by another thread
        flash[:alert] = "Sorry, one or more of those seats have just been booked by someone else. Please try again."
        raise ActiveRecord::Rollback
      end
    end

    # 5. REFACTOR: Trigger actions OUTSIDE the transaction block to avoid locking timeouts
    if booking_successful
      # Blasts through Sidekiq pipeline safely without freezing the database thread
      BookingMailer.confirmation_email(@booking).deliver_later
      redirect_to @booking, notice: "Seats reserved successfully! Please complete your payment."
    else
      redirect_to @showtime
    end

  rescue ActiveRecord::RecordInvalid
    redirect_to @showtime, alert: "Something went wrong with your booking. Please try again."
  end

  # URL: GET /bookings/:id
  def show
    # CanCanCan automatically loads the booking for us into @booking and verifies ownership!
    @tickets = @booking.tickets.includes(showtime_seat: :seat)
    
    # Matching uniform data verification template sequence string
    qr_data = "BOOKING-ID:#{@booking.id}|USER:#{@booking.user_id}|SHOWTIME:#{@booking.showtime_id}"
    qrcode = RQRCode::QRCode.new(qr_data)
    
    @qr_code_svg = qrcode.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true
    )
  end
end