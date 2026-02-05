# frozen_string_literal: true

# Background job for local (non-KI) media analysis
# This provides a fast, deterministic, and cost-free alternative to KI-based analysis
class AnalyzeLocalJob < ApplicationJob
  queue_as :default

  # Performs local analysis of Premiere Pro project media usage
  #
  # @param prproj_upload_id [Integer] The ID of the PrprojUpload to analyze
  # @param selected_sequence_ids [Array<String>] Optional list of sequence IDs to analyze
  #
  # The job will:
  # 1. Extract all media paths from the project
  # 2. Analyze only the selected sequences (or all if none specified)
  # 3. Compare used vs unused media
  # 4. Store results for display

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
      Rails.logger.info "[AnalyzeLocalJob] Starte lokale Analyse für PrprojUpload ##{prproj_upload_id}"

      # Get all media paths from the project
      all_paths = prproj_upload.referenced_media_paths
      Rails.logger.info "[AnalyzeLocalJob] #{all_paths.size} Medienpfade gefunden"

      if all_paths.empty?
        prproj_upload.update(
          ki_analysis_status: "done",
          ki_analysis_result: {
            used: [],
            unused: [],
            method: "local",
            message: "Keine Medien im Projekt gefunden"
          }.to_json
        )
        return
      end

      # Get all sequences from the project
      all_sequences = prproj_upload.sequences
      Rails.logger.info "[AnalyzeLocalJob] #{all_sequences.size} Sequenzen gefunden"

      # Filter to selected sequences if provided
      sequences = if selected_sequence_ids.present? && selected_sequence_ids.any?
                   all_sequences.select { |seq| selected_sequence_ids.include?(seq[:id]) }
      else
                   all_sequences
      end

      Rails.logger.info "[AnalyzeLocalJob] Analysiere #{sequences.size} ausgewählte Sequenzen"

      # Update progress tracking
      prproj_upload.update(ki_analysis_total: sequences.size)

      # Collect all used paths from selected sequences
      used_paths = Set.new
      skipped_sequences = []

      sequences.each_with_index do |seq, idx|
        seq_name = seq[:name] || "(unbenannt)"
        prproj_upload.update(
          ki_analysis_progress: idx + 1,
          ki_analysis_current_sequence: seq_name
        )

        begin
          # Find the sequence node in the XML document
          seq_node = prproj_upload.document.at_xpath("//sequence[@id='#{seq[:id]}']")

          if seq_node.nil?
            Rails.logger.warn "[AnalyzeLocalJob] Sequenz #{seq_name} (#{seq[:id]}) nicht im XML gefunden"
            skipped_sequences << seq_name
            next
          end

          # Extract media paths using the extended method
          sequence_paths = prproj_upload.media_paths_for_sequence_extended(seq_node)

          # Debug: Log all extracted paths for this sequence
          Rails.logger.info "[AnalyzeLocalJob] Sequenz '#{seq_name}' - #{sequence_paths.size} Pfade extrahiert:"
          sequence_paths.each do |p|
            Rails.logger.info "[AnalyzeLocalJob]   - #{p}"
          end

          used_paths.merge(sequence_paths)

          Rails.logger.info "[AnalyzeLocalJob] Sequenz #{idx + 1}/#{sequences.size}: #{seq_name} - #{sequence_paths.size} Pfade"

        rescue => e
          Rails.logger.error "[AnalyzeLocalJob] Fehler bei Sequenz #{seq_name}: #{e.message}"
          skipped_sequences << seq_name
        end
      end

      # Calculate unused paths (all paths minus used paths)
      unused_paths = all_paths.reject { |path| used_paths.include?(path) }

      # Build result
      result = {
        used: used_paths.to_a.sort,
        unused: unused_paths.sort,
        method: "local",
        statistics: {
          total_media_count: all_paths.size,
          used_media_count: used_paths.size,
          unused_media_count: unused_paths.size,
          sequences_analyzed: sequences.size - skipped_sequences.size,
          sequences_skipped: skipped_sequences.size
        },
        skipped_sequences: skipped_sequences
      }

      # Update the upload with results
      prproj_upload.update(
        ki_analysis_status: "done",
        ki_analysis_result: result.to_json,
        ki_analysis_progress: sequences.size,
        ki_analysis_current_sequence: nil
      )

      Rails.logger.info "[AnalyzeLocalJob] Analyse abgeschlossen: #{result[:statistics]}"

    rescue => e
      Rails.logger.error "[AnalyzeLocalJob] Schwerwiegender Fehler: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"

      prproj_upload.update(
        ki_analysis_status: "failed",
        ki_analysis_result: {
          error: e.message,
          method: "local"
        }.to_json
      )

      raise e
    end
  end
end
