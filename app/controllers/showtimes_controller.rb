class ShowtimesController < ApplicationController
  # Make sure the user is logged in before they try to create a showtime
  before_action :authenticate_user!, except: [:index, :show]
  
  # CanCanCan automatically checks permissions from ability.rb for every action here
  load_and_authorize_resource

  # URL: /showtimes (Everyone can see this)
  def index
    @showtimes = Showtime.where("start_time > ?", Time.current.beginning_of_day).includes(:movie, :screen).order(start_time: :asc)
  end

  # URL: /showtimes/:id (Everyone can see this to pick seats)
  def show
    # @showtime is automatically loaded by CanCanCan
    @showtime_seats = @showtime.showtime_seats.includes(:seat)
  end

  # URL: /showtimes/new (Only ADMINS can open this page)
  def new
    @showtime = Showtime.new
  end

  # Only ADMINS can submit the form to create a showtime
  def create
  # 1. Look up or build the movie by title directly from the raw params hash
  # (This completely bypasses CanCanCan's initialization)
  movie_title = params[:showtime][:movie_title]&.strip
  @movie = Movie.find_or_create_by!(title: movie_title) do |movie|
    movie.description = "Auto-generated description for #{movie_title}"
    movie.duration = 120
    movie.genre = "General"
  end

  # 2. Look up or build the screen room number
  screen_num = params[:showtime][:screen_number]
  main_theater = Theater.first || Theater.create!(name: "Grand Multiplex", location: "Main Block")
  
  @screen = Screen.find_or_create_by!(theater: main_theater, screen_number: screen_num) do |screen|
    screen.capacity = 20 
  end

  # Sync room seats configuration 
  if @screen.seats.blank?
    ['A', 'B'].each do |row|
      (1..10).each do |num|
        Seat.create!(screen: @screen, row_name: row, seat_number: num)
      end
    end
    @screen.seats.reload
  end

  # 3. Manually attach our objects to the already-initialized @showtime instance
  @showtime.movie = @movie
  @showtime.screen = @screen

  if @showtime.save
    ShowtimeSeat.transaction do
      @screen.seats.each do |seat|
        ShowtimeSeat.create!(showtime: @showtime, seat: seat, status: :available)
      end
    end

    redirect_to @showtime, notice: "Showtime successfully published!"
  else
    render :new, status: :unprocessable_entity
  end
end

private

# Clean up strong parameters so CanCanCan ONLY tries to assign real database columns!
def showtime_params
  params.require(:showtime).permit(:start_time, :price)
end
end