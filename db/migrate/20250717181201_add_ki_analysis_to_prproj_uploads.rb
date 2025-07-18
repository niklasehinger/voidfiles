class AddKiAnalysisToPrprojUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :prproj_uploads, :ki_analysis_status, :string
    add_column :prproj_uploads, :ki_analysis_result, :text
  end
end
