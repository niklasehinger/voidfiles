class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @prproj_upload = PrprojUpload.new
    @recent_uploads = current_user.prproj_uploads.order(created_at: :desc).limit(5)
  end

  def create
    @prproj_upload = PrprojUpload.new(prproj_upload_params)
    @prproj_upload.user = current_user
    if @prproj_upload.save
      session[:ki_analysis] = nil
      redirect_to prproj_upload_path(@prproj_upload, locale: I18n.locale)
    else
      @recent_uploads = current_user.prproj_uploads.order(created_at: :desc).limit(5)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def prproj_upload_params
    params.require(:prproj_upload).permit(:title, :prproj_file)
  end
end
