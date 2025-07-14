class PrprojUpload < ApplicationRecord
  has_one_attached :prproj_file

  validates :prproj_file, presence: true
end
