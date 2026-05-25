# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


MealPlan.destroy_all
Recipe.destroy_all

recipes = [
  {
    title: "Lemon Herb Chicken Bowls",
    description: "Bright chicken, rice, greens, and a quick yogurt sauce for weeknight prep.",
    prep_time_minutes: 20,
    cook_time_minutes: 25,
    servings: 4,
    category: "Dinner",
    ingredients: [
      { name: "Chicken breast", quantity: 1.5, unit: "lb", calories: 720, protein_grams: 138, carbs_grams: 0, fat_grams: 16 },
      { name: "Brown rice", quantity: 2, unit: "cup", calories: 432, protein_grams: 10, carbs_grams: 90, fat_grams: 4 },
      { name: "Cucumber", quantity: 1, unit: "item", calories: 30, protein_grams: 1, carbs_grams: 7, fat_grams: 0 },
      { name: "Greek yogurt", quantity: 0.75, unit: "cup", calories: 110, protein_grams: 18, carbs_grams: 7, fat_grams: 0 },
      { name: "Lemon", quantity: 1, unit: "item", calories: 17, protein_grams: 1, carbs_grams: 5, fat_grams: 0 }
    ]
  },
  {
    title: "Cinnamon Berry Oats",
    description: "Creamy oats with berries, chia, and almond butter.",
    prep_time_minutes: 5,
    cook_time_minutes: 8,
    servings: 2,
    category: "Breakfast",
    ingredients: [
      { name: "Rolled oats", quantity: 1, unit: "cup", calories: 300, protein_grams: 10, carbs_grams: 54, fat_grams: 6 },
      { name: "Blueberries", quantity: 1, unit: "cup", calories: 84, protein_grams: 1, carbs_grams: 21, fat_grams: 0 },
      { name: "Chia seeds", quantity: 2, unit: "tbsp", calories: 120, protein_grams: 4, carbs_grams: 10, fat_grams: 8 },
      { name: "Almond butter", quantity: 2, unit: "tbsp", calories: 196, protein_grams: 7, carbs_grams: 7, fat_grams: 18 }
    ]
  },
  {
    title: "Tuscan White Bean Soup",
    description: "A pantry-friendly soup with beans, tomatoes, kale, and herbs.",
    prep_time_minutes: 15,
    cook_time_minutes: 30,
    servings: 6,
    category: "Lunch",
    ingredients: [
      { name: "Cannellini beans", quantity: 3, unit: "can", calories: 750, protein_grams: 51, carbs_grams: 135, fat_grams: 3 },
      { name: "Crushed tomatoes", quantity: 1, unit: "can", calories: 140, protein_grams: 7, carbs_grams: 28, fat_grams: 0 },
      { name: "Kale", quantity: 1, unit: "bunch", calories: 90, protein_grams: 6, carbs_grams: 18, fat_grams: 1 },
      { name: "Vegetable broth", quantity: 4, unit: "cup", calories: 60, protein_grams: 2, carbs_grams: 8, fat_grams: 0 },
      { name: "Garlic", quantity: 4, unit: "clove", calories: 18, protein_grams: 1, carbs_grams: 4, fat_grams: 0 }
    ]
  }
]

created_recipes = recipes.map do |recipe_attributes|
  ingredients = recipe_attributes.delete(:ingredients)
  Recipe.create!(recipe_attributes).tap do |recipe|
    ingredients.each { |ingredient| recipe.ingredients.create!(ingredient) }
  end
end

MealPlan.create!([
  { recipe: created_recipes[1], planned_on: Date.current, meal_type: "Breakfast", servings: 2 },
  { recipe: created_recipes[2], planned_on: Date.current, meal_type: "Lunch", servings: 3 },
  { recipe: created_recipes[0], planned_on: Date.current + 1.day, meal_type: "Dinner", servings: 4 }
])
