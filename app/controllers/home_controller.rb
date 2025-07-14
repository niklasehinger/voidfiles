class HomeController < ApplicationController
  def index
    @prproj_upload = PrprojUpload.new
  end

  def create
    @prproj_upload = PrprojUpload.new(prproj_upload_params)
    if @prproj_upload.save
      redirect_to root_path, notice: 'Datei erfolgreich hochgeladen!'
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def prproj_upload_params
    params.require(:prproj_upload).permit(:title, :prproj_file)
  end
end
