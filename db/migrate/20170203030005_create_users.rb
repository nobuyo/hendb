class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.boolean :is_admin, null: false, default: false
      t.string :password_hash, null: false
      t.string :password_solt, null: false
      t.timestamps
    end
  end
end
