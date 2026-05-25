class CreateIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :quantity, precision: 8, scale: 2, null: false, default: 1
      t.string :unit, null: false, default: "item"

      t.timestamps
    end
  end
end
