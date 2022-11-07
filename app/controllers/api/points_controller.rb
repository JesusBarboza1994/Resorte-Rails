class Api::PointsController < ApiController
  def index
    @resorte = Resorte.second
    @points = Point.where(resorte: @resorte)
    data = { resorte: @resorte, points: @points }
    render json: data, status: :ok
  end
end
