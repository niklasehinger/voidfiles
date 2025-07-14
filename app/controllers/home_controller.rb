class HomeController < ApplicationController
  def index
    @prproj_upload = PrprojUpload.new
  end

  def create
    @prproj_upload = PrprojUpload.new(prproj_upload_params)
    if @prproj_upload.save
      respond_to do |format|
        format.turbo_stream {
          @prproj_upload = PrprojUpload.new # leeres Formular nach Erfolg
          flash.now[:notice] = 'Datei erfolgreich hochgeladen!'
          render turbo_stream: turbo_stream.replace('upload_form', partial: 'home/upload_form', locals: { prproj_upload: @prproj_upload })
        }
        format.html { redirect_to root_path, notice: 'Datei erfolgreich hochgeladen!' }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace('upload_form', partial: 'home/upload_form', locals: { prproj_upload: @prproj_upload })
        }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def faq
  end

  private

  def prproj_upload_params
    params.require(:prproj_upload).permit(:title, :prproj_file)
  end
end
