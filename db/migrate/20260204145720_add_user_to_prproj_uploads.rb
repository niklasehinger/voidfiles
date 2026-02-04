class AddUserToPrprojUploads < ActiveRecord::Migration[8.0]
  def change
    # Allow null initially since existing records don't have user_id
    # The model has `belongs_to :user, optional: true` to handle this
    add_reference :prproj_uploads, :user, null: true, foreign_key: true
  end
end
