class AddKiSelectedSequencesToPrprojUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :prproj_uploads, :ki_selected_sequences, :string, array: true, default: []
  end
end
