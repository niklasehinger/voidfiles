class AnalyzeKiJob < ApplicationJob
  queue_as :default

  def perform(prproj_upload_id, selected_sequence_ids = nil)
    prproj_upload = PrprojUpload.find(prproj_upload_id)
    prproj_upload.update(ki_analysis_status: "running", ki_analysis_result: nil)
    begin
      xml = prproj_upload.prproj_file.download.force_encoding("UTF-8")
      doc = Nokogiri::XML(xml)
      # Alle <file>-Pfade im Projekt
      all_paths = doc.xpath("//file/pathurl").map(&:text).uniq
      # Nur Sequenzen analysieren, die im Projektfenster sichtbar sind
      main_sequence_names = doc.xpath("//project//sequence/name").map(&:text).uniq
      all_sequences = doc.xpath("//sequence")
      if selected_sequence_ids.present?
        # Filtere nach übergebenen IDs (oder Fallback: nach Namen)
        sequences = all_sequences.select do |seq|
          id = seq["id"] || seq.at_xpath("uuid")&.text
          selected_sequence_ids.include?(id)
        end
      else
        sequences = all_sequences.select do |seq|
          name = seq.at_xpath("name")&.text
          main_sequence_names.include?(name)
        end
      end
      prproj_upload.update(ki_analysis_progress: 0, ki_analysis_total: sequences.size)
      used_total = []
      unused_total = []
      skipped_sequences = []
      Rails.logger.info "KI-Analyse: Starte Analyse von #{sequences.size} Sequenzen..."
      sequences.each_with_index do |seq, idx|
        seq_name = seq.at_xpath("name")&.text || "(ohne Namen)"
        retries = 0
        success = false
        begin
          Rails.logger.info "KI-Analyse: Sende Sequenz #{idx+1}/#{sequences.size} (Name: #{seq_name}) an die KI..."
          used_paths = prproj_upload.media_paths_for_sequence(seq)
          Rails.logger.info "Gefundene Medienpfade für Sequenz #{seq_name}: #{used_paths.inspect}"
          prompt = <<~PROMPT
            Du erhältst eine Liste aller Mediendateien im Projekt und eine Liste der in dieser Sequenz verwendeten Medienpfade.

            Deine Aufgabe:
            - Vergleiche beide Listen.
            - Gib ein JSON-Objekt mit zwei Feldern zurück:
              - "used": Alle Medienpfade aus der Projektliste, die in der Sequenz verwendet werden.
              - "unused": Alle Medienpfade aus der Projektliste, die NICHT in der Sequenz verwendet werden.
            - Gib ausschließlich das JSON zurück, ohne weitere Erklärungen oder Text.

            Beispiel:
            Projekt-Medienliste:
            file://.../A.mp4
            file://.../B.mp4
            file://.../C.mp4

            In der Sequenz verwendete Medien:
            file://.../A.mp4
            file://.../C.mp4

            Erwartete Ausgabe:
            {
              "used": ["file://.../A.mp4", "file://.../C.mp4"],
              "unused": ["file://.../B.mp4"]
            }

            Projekt-Medienliste:
            #{all_paths.join("\n")}

            In der Sequenz verwendete Medien:
            #{used_paths.join("\n")}
          PROMPT
          Rails.logger.info "Prompt für Sequenz #{seq_name}:\n#{prompt}"
          result = OpenaiXmlAnalyzer.new(prompt).analyze
          Rails.logger.info "Antwort für Sequenz #{seq_name}: #{result.inspect}"
          if result && result["used"].is_a?(Array) && result["unused"].is_a?(Array)
            used_total.concat(result["used"])
            unused_total.concat(result["unused"])
            success = true
          else
            raise "Leere oder ungültige Antwort"
          end
        rescue => e
          retries += 1
          Rails.logger.info "KI-Analyse: Fehler bei Sequenz #{idx+1}/#{sequences.size} (Name: #{seq_name}): #{e.message} – Versuch #{retries}/3."
          retry if retries < 3
          skipped_sequences << seq_name unless success
        end
        prproj_upload.update(ki_analysis_progress: idx + 1, ki_analysis_current_sequence: seq_name)
        Rails.logger.info "KI-Analyse: Sequenz #{idx+1}/#{sequences.size} abgeschlossen.#{' (Übersprungen)' unless success}"
      end
      used_total.uniq!
      unused_total.uniq!
      prproj_upload.update(ki_analysis_status: "done", ki_analysis_result: { used: used_total, unused: unused_total, skipped_sequences: skipped_sequences }.to_json)
    rescue => e
      prproj_upload.update(ki_analysis_status: "failed", ki_analysis_result: { error: e.message }.to_json)
      raise e
    end
  end
end
