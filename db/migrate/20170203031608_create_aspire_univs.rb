class CreateAspireUnivs < ActiveRecord::Migration[5.0]
  def change
    create_table :aspire_univs do |t|
      t.reference :user
      t.reference :univ
      t.ingeter   :priority
    end
  end
end
