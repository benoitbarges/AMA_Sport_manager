class EarningsController < ApplicationController
  before_action :set_earning, only: [ :show, :edit, :update]

  def index
    respond_to do |format|
      format.html do
        @earnings = if params[:only_past_earnings] == 'true'
                  current_user.earnings.joins(:tournament).where('tournaments.end_date <?', Date.today).where('earnings.real_amount <=?', 0).order(date: :desc)
                elsif params[:only_past_earnings] == 'false'
                  current_user.earnings.joins(:tournament).where('tournaments.end_date >?', Date.today).order(date: :desc)
                else
                  current_user.earnings.joins(:tournament).where('tournaments.end_date <?', Date.today).where('earnings.real_amount >?', 0).order(date: :desc)
                end
      end
      format.json do
        render json: format_data(current_user.earnings).as_json
      end
    end
  end

  def my_earnings
      respond_to do |format|
        format.json do
          render json: current_user.earnings.select{|earning| earning.tournament}.as_json(include: :tournament)
        end
      end
  end

  def show
    @expense = Expense.new
    @tournament = Tournament.geocoded
    @tournament = @earning.tournament
    current_user.expenses.build

    @marker = { lat: @tournament.latitude,
                lng: @tournament.longitude,
              }
    @flight = { arrival_city: @tournament.address.split(',').first,
                start_date: @tournament.start_date,
                end_date: @tournament.end_date,
              }
  end

  def new
    @earning = Earning.new
  end

  def create
    @earning = Earning.new(earning_params)
    @earning.user = current_user
    @earning.date = @earning.tournament.end_date if @earning.tournament
    if @earning.save
      if @earning.tournament
        redirect_to earning_path(@earning)
      else
        redirect_to dashboard_index_path, notice: 'Fixed Earning was successfully added.'
      end
    else
      if params[:commit] == "Add earning"
        redirect_to new_earning_path, alert: "You have made a mistake."
      else
        tournament = Tournament.find(params[:earning][:tournament_id].to_i)
        redirect_to tournament_path(tournament), alert: "You must select a forcaste amount"
      end
    end
  end

  def edit
  end

  def update
    if @earning.update(earning_params)
      redirect_to earning_path(@earning), notice: 'Gaining was successfully validated.'
    else
      redirect_to earning_path(@earning, validate: true)
    end
  end

  private

  def set_earning
    @earning = Earning.find(params[:id])
  end

  def earning_params
    params.require(:earning).permit(:date, :forecast_amount, :real_amount, :title, :category, :tournament_id)
  end

  def format_data(data)
    formatted_data = data.group_by {|e| e.date.beginning_of_month}
                        .transform_values {|v| v.pluck(:real_amount).reduce(:+)}
                        .to_a
                        .sort_by(&:first)
                        .last(12)
    {
      labels: formatted_data.map(&:first).map{|e|Date.parse(e.to_s).strftime("%B")},
      datasets: [{
        label: "Earnings",
        data: formatted_data.map(&:second),
        backgroundColor: [
          'rgba(33, 191, 115, 0.6)'
        ],
        pointBackgroundColor:
        'rgba(33, 191, 115, 0.6)',
        pointHoverBorderWidth: 4,
        pointRadius: 3,
        pointHitRadius: 10
      }]
    }
  end

end
