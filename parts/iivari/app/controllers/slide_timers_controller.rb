class SlideTimersController < ApplicationController
  before_filter :find_slide

  # GET /slide_timers
  # GET /slide_timers.xml
  def index
    @slide_timers = SlideTimer.where(:slide_id => @slide.id)
    respond_with(@slide_timers)
  end

  # GET /slide_timers/1
  # GET /slide_timers/1.xml
  def show
    @slide_timer = SlideTimer.find(params[:id])
    respond_with(@slide_timer)
  end

  # GET /slide_timers/new
  # GET /slide_timers/new.xml
  def new
    @slide_timer = SlideTimer.new
    
    @slide_timer.start_time = Time.local(0)
    @slide_timer.end_time = Time.local(0) + 23.hours + 59.minutes

    respond_with(@slide_timer)
  end

  # GET /slide_timers/1/edit
  def edit
    @slide_timer = SlideTimer.find(params[:id])
  end

  # POST /slide_timers
  # POST /slide_timers.xml
  def create
    @slide_timer = SlideTimer.new(params[:slide_timer])
    @slide_timer.slide_id = @slide.id
    @slide_timer.save
    respond_with([@slide, @slide_timer])
  end

  # PUT /slide_timers/1
  # PUT /slide_timers/1.xml
  def update
    @slide_timer = SlideTimer.find(params[:id])
    @slide_timer.update_attributes(params[:slide_timer])
    respond_with([@slide, @slide_timer])
  end

  # DELETE /slide_timers/1
  # DELETE /slide_timers/1.xml
  def destroy
    @slide_timer = SlideTimer.find(params[:id])
    @slide_timer.destroy
    respond_with([@slide, @slide_timer])
  end

  private

  def find_slide
    @slide = Slide.find(params[:slide_id])
  end
end
