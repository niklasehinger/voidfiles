class AddKiAnalysisCurrentSequenceToPrprojUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :prproj_uploads, :ki_analysis_current_sequence, :string
  end
end
