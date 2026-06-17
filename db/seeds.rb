# Clear old data to start fresh
Ticket.delete_all
Booking.delete_all
ShowtimeSeat.delete_all
Showtime.delete_all
Seat.delete_all
Screen.delete_all
Theater.delete_all
Movie.delete_all
User.delete_all

# 1. Create a Test Admin and a Test Customer
admin = User.create!(email: 'admin@gmail.com', password: 'password', role: :admin)
customer = User.create!(email: 'shauryashekhawat007@gmail.com', password: '992838', role: :customer)

# 2. Create a Movie
movie = Movie.create!(title: "Inception", description: "A thief steals corporate secrets through dream-sharing technology.", duration: 148, genre: "Sci-Fi")

# 3. Create a Theater and a Screen
theater = Theater.create!(name: "Grand Rex Cinema", location: "Downtown Metro")
screen = Screen.create!(theater: theater, screen_number: 1, capacity: 20)

# 4. Generate 20 physical seats for this Screen (2 rows: A and B, 10 seats each)
['A', 'B'].each do |row|
  (1..10).each do |num|
    Seat.create!(screen: screen, row_name: row, seat_number: num)
  end
end

# 5. Create an initial Showtime for tomorrow
Showtime.create!(
  movie: movie,
  screen: screen,
  start_time: Time.current + 1.day,
  price: 12.50
) do |showtime|
  # This block runs automatically to trigger seat setups because of our Controller logic model sync
  screen.seats.each do |seat|
    ShowtimeSeat.create!(showtime: showtime, seat: seat, status: :available)
  end
end

puts "Seeds created successfully! Admin login: admin@gmail.com, Customer login: customer@test.com. Password: 992838"