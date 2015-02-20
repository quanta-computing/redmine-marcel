class VacationsController < ApplicationController
  layout 'base'

  def index
    @vacations = Vacation.all.to_a.group_by &:validator_id?
    @vacations[true] ||= []
    @vacations[false] ||= []
  end

  def new
    @vacation = Vacation.new
    @activities = VacationType.all
  end

  def edit
    @vacation = Vacation.find params[:id]
    @activities = VacationType.all
  end

  def show
    @vacation = Vacation.find params[:id]
  end

  def update
    @vacation = Vacation.find params[:id]
    @activities = VacationType.all
    params[:vacation].delete :status
    params[:vacation].delete :gcal_event_id
    if not @vacation.updatable_by? User.current
      redirect_to @vacation, alert: 'You cannot update this (permission denied)'
    end
    if @vacation.update_attributes params[:vacation]
      redirect_to @vacation
    else
      render 'edit'
    end
  end

  def create
    @activities = VacationType.all
    params[:vacation].delete :status
    if params[:vacation][:user_id].to_i != User.current.id and not Marcel::is_admin? User.current
      redirect_to vacations_url, alert: 'You cannot create a vacation for another user'
    else
      @vacation = Vacation.new params[:vacation]
      if @vacation.save
        redirect_to vacations_url, notice: "Vacation #{@vacation.id} created"
      else
        render 'new'
      end
    end
  end

  def destroy
    @vacation = Vacation.find params[:id]
    if not @vacation.deletable_by? User.current
      redirect_to vacations_url, alert: 'You cannot update this (permission denied)'
    end
    @vacation.destroy
    redirect_to vacations_url, notice: "Vacation #{@vacation.id} deleted"
  end

  def validate
    @vacation = Vacation.find params[:id]
    status = (params[:vacation].fetch(:status, true) == 'true')
    if @vacation.validable_by? User.current
      if @vacation.validate status
        redirect_to vacations_url, notice: "Vacation #{@vacation.id} #{(status && 'validated') || 'rejected'}"
      else
        redirect_to vacations_url, alert: 'Error'
      end
    else
      redirect_to vacations_url, alert: 'You cannot validate this (permission denied)'
    end
  end

  def account
    @vacation = Vacation.find params[:id]
    accounted = (params[:vacation].fetch(:accounted, true) == 'true')
    if @vacation.accountable_by? User.current
      if @vacation.update_attributes accounted: accounted
        redirect_to vacations_url, notice: "Vacation #{@vacation.id} #{(accounted && 'accounted') || 'unacounted'}"
      else
        redirect_to vacations_url, alert: 'Error'
      end
    else
      redirect_to vacations_url, alert: 'You cannot account this (permission denied)'
    end
  end

end
