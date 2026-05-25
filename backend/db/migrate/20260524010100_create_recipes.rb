class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.text :description
      t.integer :prep_time_minutes, null: false, default: 0
      t.integer :cook_time_minutes, null: false, default: 0
      t.integer :servings, null: false, default: 1
      t.string :category, null: false, default: "Dinner"

      t.timestamps
    end
  end
end
