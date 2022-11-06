class CreateResortes < ActiveRecord::Migration[7.0]
  def change
    create_table :resortes do |t|
      t.decimal :diam
      t.decimal :dext
      t.decimal :vtas
      t.decimal :altura
      t.decimal :luz1
      t.decimal :luz2

      t.timestamps
    end
  end
end
