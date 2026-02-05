class DisabledAnalyzeKiJob < ApplicationJob
  queue_as :default

  def perform(prproj_upload_id, selected_sequence_ids = nil)
    prproj_upload = PrprojUpload.find(prproj_upload_id)

    # Update status to running
    prproj_upload.update(
      ki_analysis_status: "running",
      ki_analysis_result: nil,
      ki_analysis_progress: 0,
      ki_analysis_total: 0,
      ki_analysis_current_sequence: nil
    )

    begin
      Rails.logger.info "[AnalyzeKiJob] Starte KI-Analyse für PrprojUpload ##{prproj_upload_id}"

      # Use the new comprehensive media extraction
      all_paths = prproj_upload.referenced_media_paths
      Rails.logger.info "[AnalyzeKiJob] #{all_paths.size} Medienpfade gefunden"

      if all_paths.empty?
        prproj_upload.update(
          ki_analysis_status: "done",
          ki_analysis_result: {
            used: [],
            unused: [],
            method: "ki",
            message: "Keine Medien im Projekt gefunden"
          }.to_json
        )
        return
      end

      # Get all sequences
      all_sequences = prproj_upload.sequences
      Rails.logger.info "[AnalyzeKiJob] #{all_sequences.size} Sequenzen gefunden"

      # Filter to selected sequences if provided
      sequences = if selected_sequence_ids.present? && selected_sequence_ids.any?
                   all_sequences.select { |seq| selected_sequence_ids.include?(seq[:id]) }
      else
                   all_sequences
      end

      Rails.logger.info "[AnalyzeKiJob] Analysiere #{sequences.size} ausgewählte Sequenzen"

      # Update progress tracking
      prproj_upload.update(ki_analysis_total: sequences.size)

      # For validation: collect local analysis results
      local_used_paths = Set.new

      # For tracking
      used_total = []
      unused_total = []
      skipped_sequences = []
      validation_warnings = []
      ki_cost_estimate = 0

      sequences.each_with_index do |seq, idx|
        seq_name = seq[:name] || "(unbenannt)"
        prproj_upload.update(
          ki_analysis_progress: idx + 1,
          ki_analysis_current_sequence: seq_name
        )

        retries = 0
        success = false

        begin
          # Get local analysis first (for validation)
          seq_node = prproj_upload.document.at_xpath("//sequence[@id='#{seq[:id]}']")

          if seq_node.nil?
            Rails.logger.warn "[AnalyzeKiJob] Sequenz #{seq_name} (#{seq[:id]}) nicht im XML gefunden"
            skipped_sequences << seq_name
            next
          end

          # Use extended local extraction for better accuracy
          local_paths = prproj_upload.media_paths_for_sequence_extended(seq_node)
          local_used_paths.merge(local_paths)

          Rails.logger.info "KI-Analyse: Sende Sequenz #{idx+1}/#{sequences.size} (Name: #{seq_name}) an die KI..."

          # Build optimized prompt
          prompt = build_optimized_prompt(all_paths, local_paths, seq_name)

          # Call KI
          result = OpenaiXmlAnalyzer.new(prompt).analyze
          Rails.logger.info "Antwort für Sequenz #{seq_name}: #{result.inspect}"

          if result && result["used"].is_a?(Array) && result["unused"].is_a?(Array)

            # Validate KI results against local analysis
            ki_used_set = Set.new(result["used"].map { |p| prproj_upload.normalize_path(p) })
            local_used_set = Set.new(local_paths.map { |p| prproj_upload.normalize_path(p) })

            # Check for discrepancies
            missing_from_ki = local_used_set - ki_used_set
            extra_from_ki = ki_used_set - local_used_set

            if missing_from_ki.any? || extra_from_ki.any?
              warning = {
                sequence: seq_name,
                missing_count: missing_from_ki.size,
                extra_count: extra_from_ki.size
              }
              validation_warnings << warning
              Rails.logger.warn "[AnalyzeKiJob] Validierungs-Warnung für #{seq_name}: #{warning.inspect}"
            end

            # Use KI results (they might be more accurate for complex cases)
            used_total.concat(result["used"])
            unused_total.concat(result["unused"])

            # Estimate cost (rough approximation)
            ki_cost_estimate += (all_paths.size + local_paths.size) * 0.0001

            success = true
          else
            raise "Leere oder ungültige Antwort"
          end

        rescue => e
          retries += 1
          Rails.logger.info "KI-Analyse: Fehler bei Sequenz #{idx+1}/#{sequences.size} (Name: #{seq_name}): #{e.message} – Versuch #{retries}/3."

          if retries < 3
            retry
          else
            # Fallback to local analysis for this sequence
            Rails.logger.warn "[AnalyzeKiJob] Fallback zu lokaler Analyse für #{seq_name}"
            used_total.concat(local_paths)
            validation_warnings << {
              sequence: seq_name,
              type: "fallback",
              message: "KI-Analyse fehlgeschlagen, lokale Analyse verwendet"
            }
            skipped_sequences << seq_name
          end
        end

        Rails.logger.info "KI-Analyse: Sequenz #{idx+1}/#{sequences.size} abgeschlossen.#{' (Übersprungen)' unless success}"
      end

      # Deduplicate and calculate final results
      used_total.uniq!
      used_total.map! { |p| prproj_upload.normalize_path(p) }.compact!
      unused_total.uniq!
      unused_total.map! { |p| prproj_upload.normalize_path(p) }.compact!

      # Calculate unused as all_paths - used_total ( Medien, die in KEINER Sequenz verwendet werden)
      unused_paths = all_paths.reject { |path| used_total.include?(prproj_upload.normalize_path(path)) }

      # Build result with validation info
      result = {
        used: used_total.sort,
        unused: unused_paths.sort,
        method: "ki",
        statistics: {
          total_media_count: all_paths.size,
          used_media_count: used_total.size,
          unused_media_count: unused_paths.size,
          sequences_analyzed: sequences.size - skipped_sequences.size,
          sequences_skipped: skipped_sequences.size,
          validation_warnings: validation_warnings.size,
          estimated_cost: ki_cost_estimate.round(4)
        },
        validation_warnings: validation_warnings,
        skipped_sequences: skipped_sequences
      }

      # Update the upload with results
      prproj_upload.update(
        ki_analysis_status: "done",
        ki_analysis_result: result.to_json,
        ki_analysis_progress: sequences.size,
        ki_analysis_current_sequence: nil
      )

      Rails.logger.info "[AnalyzeKiJob] Analyse abgeschlossen: #{result[:statistics]}"

    rescue => e
      Rails.logger.error "[AnalyzeKiJob] Schwerwiegender Fehler: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}"

      prproj_upload.update(
        ki_analysis_status: "failed",
        ki_analysis_result: {
          error: e.message,
          method: "ki"
        }.to_json
      )

      raise e
    end
  end

  private

  # Builds an optimized prompt for the KI
  def build_optimized_prompt(all_paths, local_paths, seq_name)
    # Truncate paths if too many to avoid token limits
    max_paths = 500
    display_paths = all_paths.size > max_paths ? all_paths[0...max_paths] : all_paths

    <<~PROMPT
      Analysiere welche Medien aus der Projektliste in der Sequenz "#{seq_name}" verwendet werden.

      ## WICHTIG
      - Vergleiche die Pfade EXAKT (Groß-/Kleinschreibung, Pfadtrenner)
      - Achte auf versteckte oder indirekte Referenzen
      - Prüfe auch Audio-Tracks, Proxy-Medien und Nested Sequences

      ## Projekt-Medienliste (#{display_paths.size} Dateien):
      #{display_paths.map { |p| "  - #{p}" }.join("\n")}

      ## Lokal erkannte Medien in dieser Sequenz (#{local_paths.size} Dateien):
      #{local_paths.map { |p| "  - #{p}" }.join("\n")}

      ## Deine Aufgabe:
      Analysiere die Sequenz und bestimme welche Medien tatsächlich verwendet werden.
      Lokal erkannte Medien dienen als Hinweis - die KI soll diese validieren und ggf. korrigieren.

      ## Ausgabe:
      JSON mit:
      - "used": Array aller verwendeten Medienpfade (vollständige Pfade)
      - "unused": Array aller NICHT verwendeten Medienpfade
      - "confidence": Konfidenzscore (0.0-1.0) für diese Analyse
      - "notes": Kurze Notiz falls Unsicherheiten

      KEINE Erklärungen, NUR das JSON-Objekt.
    PROMPT
  end
end
