class CreateMealPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_plans do |t|
      t.references :recipe, null: false, foreign_key: true
      t.date :planned_on, null: false
      t.string :meal_type, null: false
      t.integer :servings, null: false, default: 1
      t.string :notes

      t.timestamps
    end

    add_index :meal_plans, [:planned_on, :meal_type]
  end
end
