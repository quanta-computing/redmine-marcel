class VacationTypesController < ApplicationController
  layout 'base'

  def index
    @types = VacationType.all
  end

  def new
    @type = VacationType.new
  end

  def edit
    @type = VacationType.find params[:id]
  end

  def show
    @type = VacationType.find params[:id]
  end

  def create
    @type = VacationType.new params[:vacation_type]
    if not is_manager? User.current
      redirect_to vacation_types_url, alert: "Permission denied"
    elsif @type.save
      redirect_to vacation_types_url, notice: "Vacation type '#{@type.name}' created"
    else
      render 'new'
    end
  end

  def update
    @type = VacationType.find params[:id]
    if not is_manager? User.current
      redirect_to vacation_types_url, alert: "Permission denied"
    elsif @type.update_attributes params[:vacation_type]
      redirect_to vacation_types_url, notice: "Vacation type '#{@type.name}' updated"
    else
      render 'edit'
    end
  end

  def destroy
    @type = VacationType.find params[:id]
    if not is_manager? User.current
      redirect_to vacation_types_url, alert: "Permission denied"
    else
      @type.destroy
      redirect_to vacation_types_url, notice: "Vacation type '#{@type.name}' deleted"
    end
  end

  def is_manager?(user)
    VacationType.manageable_by? user
  end

end
