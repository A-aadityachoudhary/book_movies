class ShowtimesController < ApplicationController
  # Make sure the user is logged in before they try to create a showtime
  before_action :authenticate_user!, except: [:index, :show]
  
  # CanCanCan automatically checks permissions from ability.rb for every action here
  load_and_authorize_resource

  # URL: /showtimes (Everyone can see this)
  def index
    @showtimes = Showtime.where("start_time > ?", Time.current)
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
    @showtime = Showtime.new(showtime_params)
    
    if @showtime.save
      # Crucial Step: When a showtime is created, automatically generate 
      # a 'ShowtimeSeat' tracker for every single physical seat in that screen room.
      @showtime.screen.seats.each do |seat|
        ShowtimeSeat.create!(showtime: @showtime, seat: seat, status: :available)
      end
      
      redirect_to @showtime, notice: "Showtime successfully created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  # Strong parameters to safely allow specific data into the database
  def showtime_params
    params.require(:showtime).permit(:movie_id, :screen_id, :start_time, :price)
  end
end