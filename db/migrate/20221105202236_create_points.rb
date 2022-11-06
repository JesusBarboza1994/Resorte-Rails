class CreatePoints < ActiveRecord::Migration[7.0]
  def change
    create_table :points do |t|
      t.decimal :x
      t.decimal :y
      t.decimal :z
      t.references :resorte, null: false, foreign_key: true

      t.timestamps
    end
  end
end
