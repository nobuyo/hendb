class AddExamIdToUniv < ActiveRecord::Migration[5.0]
  def change
    change_table :univs do |t|
      t.references :exam
    end
  end
end
