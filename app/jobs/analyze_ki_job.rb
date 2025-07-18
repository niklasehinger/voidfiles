class AnalyzeKiJob < ApplicationJob
  queue_as :default

  def perform(prproj_upload_id)
    prproj_upload = PrprojUpload.find(prproj_upload_id)
    prproj_upload.update(ki_analysis_status: 'running', ki_analysis_result: nil)
    begin
      xml = prproj_upload.prproj_file.download.force_encoding("UTF-8")
      doc = Nokogiri::XML(xml)
      # Alle Pfade aus allen <file>-Elementen
      all_paths = doc.xpath('//file/pathurl').map(&:text).uniq
      # IDs der genutzten Dateien aus allen <clipitem> in <sequence>
      used_file_ids = doc.xpath('//sequence//clipitem/file/@id').map(&:text).uniq
      # Die zugehörigen Pfade aus <file>-Elementen
      used_paths = used_file_ids.map do |fid|
        node = doc.at_xpath("//file[@id='#{fid}']/pathurl")
        node&.text
      end.compact.uniq
      # Chunking wie gehabt
      chunk_size = 100
      all_chunks = all_paths.each_slice(chunk_size).to_a
      prproj_upload.update(ki_analysis_progress: 0, ki_analysis_total: all_chunks.size)
      used_total = []
      unused_total = []
      all_chunks.each_with_index do |all_chunk, idx|
        prompt = "Hier ist eine Liste aller Medienpfade:\n" +
          all_chunk.join("\n") +
          "\n\nUnd hier die in der Timeline verwendeten Pfade:\n" +
          used_paths.join("\n") +
          "\n\nGib mir als JSON zurück, welche Pfade genutzt und welche ungenutzt sind. Beispiel: {\"used\":[...],\"unused\":[...]}
"
        result = OpenaiXmlAnalyzer.new(prompt).analyze
        if result
          used_total.concat(result["used"]) if result["used"]
          unused_total.concat(result["unused"]) if result["unused"]
        end
        prproj_upload.update(ki_analysis_progress: idx + 1)
      end
      used_total.uniq!
      unused_total.uniq!
      prproj_upload.update(ki_analysis_status: 'done', ki_analysis_result: {used: used_total, unused: unused_total}.to_json)
    rescue => e
      prproj_upload.update(ki_analysis_status: 'failed', ki_analysis_result: {error: e.message}.to_json)
      raise e
    end
  end
end
