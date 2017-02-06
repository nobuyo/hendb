class CreateUnivs < ActiveRecord::Migration[5.0]
  def change
    create_table :univs do |t|
      t.string  :name, null: false
      t.string  :pref, null: false
      t.string  :dept, null: false
      t.integer :deviation_value, null: false
      t.date    :exam_date, null: false
      t.date    :result_date, null: false
      t.date    :affirmation_date
      t.integer :admit_units
      t.text    :remark
      t.timestamps
    end
  end
end
