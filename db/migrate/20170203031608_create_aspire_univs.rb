class CreateAspireUnivs < ActiveRecord::Migration[5.0]
  def change
    create_table :aspire_univs do |t|
      t.references :user
      t.references :univ
    end
  end
end
