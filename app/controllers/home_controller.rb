class HomeController < ApplicationController
  def index
    @prproj_upload = PrprojUpload.new
  end

  def create
    @prproj_upload = PrprojUpload.new(prproj_upload_params)
    if @prproj_upload.save
      redirect_to prproj_upload_path(@prproj_upload)
    else
      render :index, status: :unprocessable_entity
    end
  end

  def show
    @prproj_upload = PrprojUpload.find(params[:id])
  end

  def faq
  end

  private

  def prproj_upload_params
    params.require(:prproj_upload).permit(:title, :prproj_file)
  end
end
