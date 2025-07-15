class AddMediaPathsToPrprojUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :prproj_uploads, :media_paths, :text
  end
end
