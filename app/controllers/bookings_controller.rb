class BookingsController < ApplicationController
  # Make sure the customer is logged in before they can buy a ticket
  before_action :authenticate_user!
  
  # CanCanCan automatically checks if this user is allowed to make a booking
  load_and_authorize_resource

  # URL: POST /bookings
  def create
    @showtime = Showtime.find(params[:showtime_id])
    
    # params[:seat_ids] is an array of IDs (e.g., [12, 13, 14])
    selected_seat_ids = params[:seat_ids] 

    if selected_seat_ids.blank?
      redirect_to @showtime, alert: "Please select at least one seat before booking."
      return
    end

    # A Transaction ensures that everything inside this block either succeeds together, 
    # or fails completely if even one part goes wrong.
    ActiveRecord::Base.transaction do
      
      # 1. Fetch the seats and lock them in the database so no other user can modify them right now
      seats = ShowtimeSeat.where(id: selected_seat_ids).lock("FOR UPDATE")

      # 2. Safety Check: Ensure EVERY single seat chosen is actually still 'available'
      if seats.all?(&:available?)
        
        # 3. Create the parent Booking record
        @booking = current_user.bookings.create!(
          showtime: @showtime,
          total_price: seats.size * @showtime.price,
          status: :pending # Starts as pending until payment is made
        )

        # 4. Change each seat status to 'booked' and create an individual ticket row
        seats.each do |seat|
          seat.update!(status: :booked)
          Ticket.create!(booking: @booking, showtime_seat: seat)
        end

        # 5. Success! Take them to the checkout summary page
        redirect_to @booking, notice: "Seats reserved successfully! Please complete your payment."
      
      else
        # If even one seat was already taken by someone else, cancel the whole process
        redirect_to @showtime, alert: "Sorry, one or more of those seats have just been booked by someone else. Please try again."
        raise ActiveRecord::Rollback # Cancels the database changes made inside this block
      end
    end

  rescue ActiveRecord::RecordInvalid
    redirect_to @showtime, alert: "Something went wrong with your booking. Please try again."
  end

  # URL: GET /bookings/:id
  def show
    # CanCanCan automatically loads the booking for us into @booking
    @tickets = @booking.tickets.includes(showtime_seat: :seat)
    # Create a unique data string for the ticket checker
    qr_data = "BOOKING-ID:#{@booking.id}|USER:#{@booking.user_id}|SHOWTIME:#{@booking.showtime_id}"
    
    # Initialize the RQRCode engine
    qrcode = RQRCode::QRCode.new(qr_data)
    
    # Render the matrix structure into a clean, lightweight SVG string
    @qr_code_svg = qrcode.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true
    )
  end
end