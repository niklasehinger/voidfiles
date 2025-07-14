class PrprojUpload < ApplicationRecord
  has_one_attached :prproj_file
  validates :prproj_file, presence: true
  validate :xml_file_type

  require 'nokogiri'

  # Gibt ein Array aller im Projekt referenzierten Medienpfade zurück
  def referenced_media_paths
    return [] unless prproj_file.attached?
    file = prproj_file.download
    doc = Nokogiri::XML(file) { |c| c.strict.noblanks }
    doc.xpath('//pathurl').map(&:text).uniq
  rescue => e
    Rails.logger.error("Fehler beim Auslesen der Medienpfade: #{e.message}")
    []
  end

  # Baut aus allen Pfaden einen verschachtelten Hash (Ordnerbaum)
  def media_tree
    tree = {}
    referenced_media_paths.each do |path|
      parts = path.sub(/^file:\/\/localhost\//, '').split(/[\\\/]/)
      current = tree
      parts.each do |part|
        current[part] ||= {}
        current = current[part]
      end
    end
    tree
  end

  private

  def xml_file_type
    return unless prproj_file.attached?
    unless prproj_file.filename.to_s.downcase.ends_with?('.xml')
      errors.add(:prproj_file, 'muss eine .xml-Datei sein')
    end
  end
end
