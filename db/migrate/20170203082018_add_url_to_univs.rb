class AddUrlToUnivs < ActiveRecord::Migration[5.0]
  def change
    change_table :univs do |t|
      t.string :document_url
    end
  end
end
