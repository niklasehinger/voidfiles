class CreatePrprojUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :prproj_uploads do |t|
      t.string :title

      t.timestamps
    end
  end
end
