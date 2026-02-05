class PrprojUploadsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_prproj_upload, only: [:show, :sequences_select, :analyze_ki, :analyze_local, :progress, :export_unused, :batch_analyze, :destroy]
  before_action :authorize_prproj_upload, only: [:show, :sequences_select, :analyze_ki, :analyze_local, :progress, :export_unused, :batch_analyze, :destroy]

  def show
    @ki_analysis = @prproj_upload.ki_analysis_result.present? ? JSON.parse(@prproj_upload.ki_analysis_result) : nil
    @ki_status = @prproj_upload.ki_analysis_status
    @sequences = @prproj_upload.sequences
  end

  def create
    @prproj_upload = PrprojUpload.new(prproj_upload_params)
    @prproj_upload.user = current_user

    if @prproj_upload.save
      redirect_to prproj_upload_path(@prproj_upload, locale: I18n.locale), 
                  notice: "Datei erfolgreich hochgeladen. Wähle die zu analysierenden Sequenzen aus."
    else
      # Render the dashboard with errors
      @prproj_uploads = current_user.prproj_uploads.order(created_at: :desc).limit(5)
      render "dashboard/index", status: :unprocessable_entity
    end
  end

  def analyze_ki
    selected_sequences = params[:sequences] || []
    @prproj_upload.update(ki_analysis_status: "pending", ki_analysis_result: nil, ki_selected_sequences: selected_sequences)
    AnalyzeKiJob.perform_later(@prproj_upload.id, selected_sequences)
    redirect_to prproj_upload_path(@prproj_upload, locale: I18n.locale), notice: "Die KI-Analyse wurde für die ausgewählten Sequenzen gestartet und läuft im Hintergrund."
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
                notice: "Die lokale Analyse wurde gestartet und läuft im Hintergrund. Keine KI-Kosten."
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

  def export_unused
    unless @prproj_upload.ki_analysis_result.present?
      redirect_to @prproj_upload, alert: "Keine Analyseergebnisse vorhanden. Bitte führe zuerst eine Analyse durch."
      return
    end

    analysis = JSON.parse(@prproj_upload.ki_analysis_result)
    unused_paths = analysis["unused"] || []

    # Group by folder for better organization
    unused_by_folder = Hash.new { |h, k| h[k] = [] }
    unused_paths.each { |path| unused_by_folder[File.dirname(path)] << path }

    respond_to do |format|
      format.txt do
        # Organized TXT export with folders
        content = unused_by_folder.map do |folder, paths|
          "#{folder}/\n" +
          "#{'=' * 80}\n" +
          paths.map { |p| "  #{File.basename(p)}" }.join("\n")
        end.join("\n\n")
        
        render plain: content,
               content_type: "text/plain",
               filename: "unused_media_#{Date.today}.txt"
      end
      format.csv do
        # CSV with folder structure
        csv_string = CSV.generate do |csv|
          csv << ["Folder", "Filename", "Full Path"]
          unused_paths.each do |p|
            csv << [File.dirname(p), File.basename(p), p]
          end
        end
        send_data csv_string,
                  filename: "unused_media_#{Date.today}.csv",
                  type: "text/csv"
      end
      format.json do
        result = {
          export_date: Time.current.iso8601,
          project: @prproj_upload.title,
          unused_count: unused_paths.size,
          grouped_by_folder: unused_by_folder.transform_keys(&:to_s),
          paths: unused_paths
        }
        render json: result
      end
    end
  rescue JSON::ParserError => e
    redirect_to @prproj_upload, alert: "Fehler beim Parsen der Analyseergebnisse: #{e.message}"
  end

  def batch_analyze
    selected_sequences = params[:sequences] || []

    if selected_sequences.empty?
      redirect_to sequences_select_prproj_upload_path(@prproj_upload, locale: I18n.locale),
                  alert: "Bitte wähle mindestens eine Sequenz aus."
      return
    end

    analysis_type = params[:analysis_type] || "local"

    if analysis_type == "ki"
      analyze_ki
    else
      analyze_local
    end
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
