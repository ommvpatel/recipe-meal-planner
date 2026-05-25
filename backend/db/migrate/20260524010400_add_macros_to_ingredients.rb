class AddMacrosToIngredients < ActiveRecord::Migration[8.0]
  def change
    add_column :ingredients, :calories, :decimal, precision: 8, scale: 2, null: false, default: 0
    add_column :ingredients, :protein_grams, :decimal, precision: 8, scale: 2, null: false, default: 0
    add_column :ingredients, :carbs_grams, :decimal, precision: 8, scale: 2, null: false, default: 0
    add_column :ingredients, :fat_grams, :decimal, precision: 8, scale: 2, null: false, default: 0
  end
end
