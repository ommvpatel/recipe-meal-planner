module Api
  class ShoppingListsController < ApplicationController
    def show
      meal_plans = MealPlan.includes(recipe: :ingredients).order(:planned_on)
      render json: shopping_list_json(meal_plans)
    end

    private

    def shopping_list_json(meal_plans)
      meal_plans.each_with_object({}) do |meal_plan, list|
        multiplier = meal_plan.servings.to_f / meal_plan.recipe.servings

        meal_plan.recipe.ingredients.each do |ingredient|
          key = "#{ingredient.name.downcase}|#{ingredient.unit.downcase}"
          list[key] ||= {
            name: ingredient.name,
            unit: ingredient.unit,
            quantity: 0.0
          }
          list[key][:quantity] += ingredient.quantity.to_f * multiplier
        end
      end.values.sort_by { |item| item[:name].downcase }
    end
  end
end
