class PrprojUploadsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_prproj_upload, only: [ :show, :sequences_select, :analyze_local, :progress, :batch_analyze, :destroy ]
  before_action :authorize_prproj_upload, only: [ :show, :sequences_select, :analyze_local, :progress, :batch_analyze, :destroy ]

  def show
    @ki_analysis = @prproj_upload.ki_analysis_result.present? ? JSON.parse(@prproj_upload.ki_analysis_result) : nil
    @ki_status = @prproj_upload.ki_analysis_status
    @sequences = @prproj_upload.sequences
  end

  def create
    @prproj_upload = PrprojUpload.new(prproj_upload_params)
    @prproj_upload.user = current_user

    if @prproj_upload.save redirect_to prproj_upload_path(@prproj_upload, locale: I18n.locale),
                  notice: "Datei erfolgreich hochgeladen. Wähle die zu analysierenden Sequenzen aus."
    else
      # Render the dashboard with errors
      @prproj_uploads = current_user.prproj_uploads.order(created_at: :desc).limit(5)
      render "dashboard/index", status: :unprocessable_entity
    end
  end

  def analyze_local
    selected_sequences = params[:sequences] || []

    @prproj_upload.update(
      ki_analysis_status: "pending",
      ki_analysis_result: nil,
      ki_selected_sequences: selected_sequences
    )

    AnalyzeLocalJob.perform_later(@prproj_upload.id, selected_sequences)

    redirect_to prproj_upload_path(@prproj_upload, locale: I18n.locale),
                notice: "Die lokale Analyse wurde gestartet und läuft im Hintergrund."
  end

  def progress
    render json: {
      progress: @prproj_upload.ki_analysis_progress || 0,
      total: @prproj_upload.ki_analysis_total || 0,
      status: @prproj_upload.ki_analysis_status,
      current_sequence: @prproj_upload.ki_analysis_current_sequence,
      method: @prproj_upload.ki_analysis_result.present? ? JSON.parse(@prproj_upload.ki_analysis_result)["method"] : nil
    }
  end

  def sequences_select
    @sequences = @prproj_upload.sequences
  end


  def batch_analyze
    selected_sequences = params[:sequences] || []

    if selected_sequences.empty?
      redirect_to sequences_select_prproj_upload_path(@prproj_upload, locale: I18n.locale),
                  alert: "Bitte wähle mindestens eine Sequenz aus."
      return
    end

    analyze_local
  end

  def destroy
    @prproj_upload.destroy
    redirect_to profile_path(locale: I18n.locale), notice: "Projekt wurde gelöscht."
  end

  private

  def prproj_upload_params
    params.require(:prproj_upload).permit(:title, :prproj_file)
  end

  def set_prproj_upload
    @prproj_upload = PrprojUpload.find(params[:id])
  end

  def authorize_prproj_upload
    unless @prproj_upload.user == current_user
      redirect_to dashboard_path(locale: I18n.locale), alert: "Du hast keine Berechtigung, auf dieses Projekt zuzugreifen."
    end
  end
end
