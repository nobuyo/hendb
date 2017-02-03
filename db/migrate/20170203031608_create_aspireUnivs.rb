class CreateAspireunivs < ActiveRecord::Migration[5.0]
  def change
    create_table :aspire_univs do |t|
      t.ingeter :priority
    end
  end
end
