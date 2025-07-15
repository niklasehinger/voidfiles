class PrprojUploadsController < ApplicationController
  def show
    @prproj_upload = PrprojUpload.find(params[:id])
    @ki_analysis = session[:ki_analysis]
  end

  def analyze_ki
    @prproj_upload = PrprojUpload.find(params[:id])
    xml = @prproj_upload.prproj_file.download.force_encoding("UTF-8")
    # Extrahiere nur die relevanten Pfade
    doc = Nokogiri::XML(xml)
    all_paths = doc.xpath('//pathurl').map(&:text).uniq
    used_paths = doc.xpath('//sequence//pathurl').map(&:text).uniq
    prompt = "Hier ist eine Liste aller Medienpfade:\n" +
      all_paths.join("\n") +
      "\n\nUnd hier die in der Timeline verwendeten Pfade:\n" +
      used_paths.join("\n") +
      "\n\nGib mir als JSON zurück, welche Pfade genutzt und welche ungenutzt sind. Beispiel: {\"used\":[...],\"unused\":[...]}"
    result = OpenaiXmlAnalyzer.new(prompt).analyze
    if result
      session[:ki_analysis] = result
      redirect_to analysis_result_prproj_upload_path(@prproj_upload)
    else
      redirect_to @prproj_upload, alert: "KI-Analyse fehlgeschlagen. Bitte versuche es erneut."
    end
  end

  def analysis_result
    @prproj_upload = PrprojUpload.find(params[:id])
    @ki_analysis = session[:ki_analysis]
    unless @ki_analysis.present?
      redirect_to @prproj_upload, alert: "Keine Analyseergebnisse vorhanden. Bitte führe zuerst eine KI-Analyse durch."
    end
  end
end 