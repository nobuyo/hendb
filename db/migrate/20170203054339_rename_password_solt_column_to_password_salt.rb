class RenamePasswordSoltColumnToPasswordSalt < ActiveRecord::Migration[5.0]
  def change
    rename_column :users, :password_solt, :password_salt
  end
end
