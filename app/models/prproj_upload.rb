class PrprojUpload < ApplicationRecord
  belongs_to :user, optional: true

  has_one_attached :prproj_file
  validates :prproj_file, presence: true
  validate :xml_file_type

  before_validation :set_default_title, on: :create

  attribute :ki_selected_sequences, :string, array: true, default: []

  # Gibt ein Array aller im Projekt referenzierten Medienpfade zurück
  def referenced_media_paths
    return [] unless prproj_file.attached?
    file = prproj_file.download
    doc = Nokogiri::XML(file) { |c| c.strict.noblanks }
    doc.xpath("//pathurl").map(&:text).uniq
  rescue => e
    Rails.logger.error("Fehler beim Auslesen der Medienpfade: #{e.message}")
    []
  end

  # Baut aus allen Pfaden einen verschachtelten Hash (Ordnerbaum)
  def media_tree
    tree = {}
    referenced_media_paths.each do |path|
      parts = path.sub(/^file:\/\/localhost\//, "").split(/[\\\/]/)
      current = tree
      parts.each do |part|
        current[part] ||= {}
        current = current[part]
      end
    end
    tree
  end

  # Gibt ein Array aller Sequenzen im Projekt zurück (Name, ggf. weitere Infos)
  def sequences
    return [] unless prproj_file.attached?
    file = prproj_file.download
    doc = Nokogiri::XML(file) { |c| c.strict.noblanks }
    doc.xpath("//sequence").map do |seq|
      {
        name: seq.at_xpath("name")&.text,
        duration: seq.at_xpath("duration")&.text,
        id: seq["id"] || seq.at_xpath("uuid")&.text
      }
    end
  rescue => e
    Rails.logger.error("Fehler beim Auslesen der Sequenzen: #{e.message}")
    []
  end

  # Extrahiert alle in einer Sequenz verwendeten Medienpfade (file://...)
  def media_paths_for_sequence(sequence_node)
    # 1. Alle <clipitem> in der Sequenz
    clipitems = sequence_node.xpath(".//clipitem")
    # 2. Alle <file>-IDs aus den clipitems
    file_ids = clipitems.map { |ci| ci.at_xpath("./file")&.[]("id") }.compact.uniq
    Rails.logger.info "Gefundene file_ids in clipitems: #{file_ids.inspect}"
    # 3. Gesamtes XML-Dokument laden
    xml_doc = prproj_file.attached? ? Nokogiri::XML(prproj_file.download) : nil
    return [] unless xml_doc
    # 4. Für jede file_id den Pfad extrahieren
    paths = file_ids.map do |fid|
      file_node = xml_doc.at_xpath("//file[@id='#{fid}']")
      if file_node
        path = file_node.at_xpath("./pathurl")&.text
        Rails.logger.info "Pfad für file_id #{fid}: #{path}"
        path
      else
        Rails.logger.info "Kein <file> mit id='#{fid}' gefunden!"
        nil
      end
    end.compact.uniq
    Rails.logger.info "Gefundene Medienpfade für Sequenz #{sequence_node.at_xpath('name')&.text}: #{paths.inspect}"
    paths
  end

  private

  def set_default_title
    if self.title.blank?
      self.title = I18n.l(Time.current, format: :short)
    end
  end

  def xml_file_type
    return unless prproj_file.attached?
    unless prproj_file.filename.to_s.downcase.ends_with?(".xml")
      errors.add(:prproj_file, "muss eine .xml-Datei sein")
    end
  end
end
