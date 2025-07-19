require "test_helper"

class PrprojUploadTest < ActiveSupport::TestCase
  test "should create prproj upload with valid file" do
    upload = PrprojUpload.new(title: "Test Upload")
    upload.prproj_file.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "sample.xml")),
      filename: "sample.xml",
      content_type: "application/xml"
    )
    
    assert upload.save
    assert upload.prproj_file.attached?
  end

  test "should extract sequences from XML file" do
    upload = PrprojUpload.new(title: "Test Upload")
    upload.prproj_file.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "sample.xml")),
      filename: "sample.xml",
      content_type: "application/xml"
    )
    upload.save!
    
    sequences = upload.sequences
    assert_not_empty sequences
    assert sequences.first.is_a?(Hash)
    assert sequences.first.key?(:name)
  end

  test "should extract media paths from sequences" do
    upload = PrprojUpload.new(title: "Test Upload")
    upload.prproj_file.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "sample.xml")),
      filename: "sample.xml",
      content_type: "application/xml"
    )
    upload.save!
    
    sequences = upload.sequences
    if sequences.any?
      sequence_node = Nokogiri::XML(upload.prproj_file.download).at_xpath('//sequence')
      if sequence_node
        media_paths = upload.media_paths_for_sequence(sequence_node)
        assert media_paths.is_a?(Array)
      end
    end
  end

  test "should build media tree from paths" do
    upload = PrprojUpload.new(title: "Test Upload")
    upload.prproj_file.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "sample.xml")),
      filename: "sample.xml",
      content_type: "application/xml"
    )
    upload.save!
    
    tree = upload.media_tree
    assert tree.is_a?(Hash)
  end

  test "should set default title if blank" do
    upload = PrprojUpload.new
    upload.prproj_file.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "sample.xml")),
      filename: "sample.xml",
      content_type: "application/xml"
    )
    
    assert upload.save
    assert_not_nil upload.title
    assert_not_empty upload.title
  end

  test "should validate XML file type" do
    upload = PrprojUpload.new(title: "Test Upload")
    upload.prproj_file.attach(
      io: StringIO.new("not xml content"),
      filename: "test.txt",
      content_type: "text/plain"
    )
    
    assert_not upload.valid?
    assert_includes upload.errors[:prproj_file], "muss eine .xml-Datei sein"
  end
end
