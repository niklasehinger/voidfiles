class AddKiAnalysisProgressToPrprojUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :prproj_uploads, :ki_analysis_progress, :integer
    add_column :prproj_uploads, :ki_analysis_total, :integer
  end
end
