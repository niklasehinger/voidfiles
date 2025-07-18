class PrprojUploadsController < ApplicationController
  def show
    @prproj_upload = PrprojUpload.find(params[:id])
    @ki_analysis = @prproj_upload.ki_analysis_result.present? ? JSON.parse(@prproj_upload.ki_analysis_result) : nil
    @ki_status = @prproj_upload.ki_analysis_status
  end

  def analyze_ki
    @prproj_upload = PrprojUpload.find(params[:id])
    @prproj_upload.update(ki_analysis_status: 'pending', ki_analysis_result: nil)
    AnalyzeKiJob.perform_later(@prproj_upload.id)
    redirect_to prproj_upload_path(@prproj_upload, locale: I18n.locale), notice: 'Die KI-Analyse wurde gestartet und läuft im Hintergrund.'
  end

  def analysis_result
    @prproj_upload = PrprojUpload.find(params[:id])
    @ki_analysis = session[:ki_analysis]
    unless @ki_analysis.present?
      redirect_to @prproj_upload, alert: "Keine Analyseergebnisse vorhanden. Bitte führe zuerst eine KI-Analyse durch."
    end
  end

  def progress
    prproj_upload = PrprojUpload.find(params[:id])
    render json: {
      progress: prproj_upload.ki_analysis_progress || 0,
      total: prproj_upload.ki_analysis_total || 0,
      status: prproj_upload.ki_analysis_status
    }
  end
end 