class CreateUnivs < ActiveRecord::Migration[5.0]
  def change
    create_table :univs do |t|
      t.string  :name, null: :false
      t.string  :pref
      t.integer :deviation_value
      t.date    :exam_date
      t.date    :result_date
      t.date    :affirmation_date
      t.integer :admit_units
      t.text    :remark
      t.timestamps
    end
  end
end
