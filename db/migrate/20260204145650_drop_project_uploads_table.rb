class DropProjectUploadsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :project_uploads, if_exists: true
  end

  def down
    create_table :project_uploads do |t|
      t.string :title
      t.timestamps
    end
  end
end
