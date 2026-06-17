class ShowtimesController < ApplicationController
  # Require user authentication
  before_action :authenticate_user!, except: [:index, :show]
  
  # CanCanCan automatically loads resource records and runs permission hooks
  load_and_authorize_resource

  # URL: GET /showtimes
  def index
    @showtimes = @showtimes.where("start_time > ?", Time.current.beginning_of_day).includes(:movie, :screen).order(start_time: :asc)
  end

  # URL: GET /showtimes/:id
  def show
    # @showtime is automatically loaded by CanCanCan
    @showtime_seats = @showtime.showtime_seats.includes(:seat)
  end

  # URL: GET /showtimes/new
  def new
    # @showtime is automatically initialized by CanCanCan
  end

  # URL: POST /showtimes
  def create
    # 1. Fetch or initialize the parent Movie profile using the permitted parameter keys
    movie_title = showtime_params[:movie_title]&.strip
    @movie = Movie.find_or_create_by!(title: movie_title) do |movie|
      movie.description = "Auto-generated description for #{movie_title}"
      movie.duration = 120
      movie.genre = "General"
    end

    # 2. Fetch or initialize the target theater screen room allocation grid
    screen_num = showtime_params[:screen_number]
    main_theater = Theater.first || Theater.create!(name: "Grand Multiplex", location: "Main Block")
    
    @screen = Screen.find_or_create_by!(theater: main_theater, screen_number: screen_num) do |screen|
      screen.capacity = 20 
    end

    # Synchronize default physical seat topology map blueprints if blank
    if @screen.seats.blank?
      ['A', 'B'].each do |row|
        (1..10).each do |num|
          Seat.create!(screen: @screen, row_name: row, seat_number: num)
        end
      end
      @screen.seats.reload
    end

    # 3. Apply the compiled model relations directly to the CanCanCan-managed instance
    @showtime.movie = @movie
    @showtime.screen = @screen

    if @showtime.save
      # Batch initialize transactional session showtime seating nodes
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

  # This lets CanCanCan map attributes safely without dropping data arrays on submission.
  def showtime_params
    params.require(:showtime).permit(:start_time, :price, :movie_title, :screen_number)
  end
end