class PrprojUploadsController < ApplicationController
  def show
    @prproj_upload = PrprojUpload.find(params[:id])
  end
end 