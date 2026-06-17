require 'rqrcode'

class BookingMailer < ApplicationMailer
  # Change this to match your direct SMTP username email!
  default from: 'your-email@yourdomain.com'

  def confirmation_email(booking)
    @booking = booking
    @user = @booking.user
    @showtime = @booking.showtime
    @movie = @showtime.movie

    # 1. Build matching structural verification string data
    @qr_string = "BOOKING-ID:#{@booking.id}|USER:#{@booking.user_id}|SHOWTIME:#{@showtime.id}"
    qrcode = RQRCode::QRCode.new(@qr_string)

    # 2. Compile to a PNG image stream matrix blob
    png_blob = qrcode.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_INDEXED,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 6,
      size: 250
    )

    # 3. Attach the binary data stream directly as an inline image asset element
    attachments.inline['ticket_qr.png'] = {
      mime_type: 'image/png',
      content: png_blob.to_s
    }

    # 4. Trigger compilation (MUST BE AT THE BOTTOM)
    mail(
      to: @user.email,
      subject: "🎟️ Your Ticket Confirmation for #{@movie.title}!"
    )
  end
end