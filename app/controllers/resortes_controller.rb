class ResortesController < ApplicationController
  before_action :set_resorte, only: %i[ show edit update destroy ]

  # GET /resortes or /resortes.json
  def index
    @resortes = Resorte.all
  end

  # GET /resortes/1 or /resortes/1.json
  def show
  end

  # GET /resortes/new
  def new
    @resorte = Resorte.new
  end

  # GET /resortes/1/edit
  def edit
  end

  # POST /resortes or /resortes.json
  def create
    @resorte = Resorte.new(resorte_params) 
    respond_to do |format|
      if @resorte.save
        format.html { redirect_to resorte_url(@resorte), notice: "Resorte was successfully created." }
        format.json { render :show, status: :created, location: @resorte }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @resorte.errors, status: :unprocessable_entity }
      end
    end
    Resorte.fem(@resorte)
  end

  # PATCH/PUT /resortes/1 or /resortes/1.json
  def update
    respond_to do |format|
      if @resorte.update(resorte_params)
        format.html { redirect_to resorte_url(@resorte), notice: "Resorte was successfully updated." }
        format.json { render :show, status: :ok, location: @resorte }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @resorte.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /resortes/1 or /resortes/1.json
  def destroy
    @resorte.destroy

    respond_to do |format|
      format.html { redirect_to resortes_url, notice: "Resorte was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_resorte
      @resorte = Resorte.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def resorte_params
      params.require(:resorte).permit(:diam, :dext, :vtas, :altura, :luz1, :luz2)
    end
end
