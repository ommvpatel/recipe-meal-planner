module Api
  class MealPlansController < ApplicationController
    before_action :set_meal_plan, only: [:update, :destroy]

    def index
      meal_plans = MealPlan.includes(recipe: :ingredients).order(:planned_on, :meal_type)
      render json: meal_plans.map { |meal_plan| meal_plan_json(meal_plan) }
    end

    def create
      meal_plan = MealPlan.create!(meal_plan_params)
      render json: meal_plan_json(meal_plan), status: :created
    rescue ActiveRecord::RecordInvalid => error
      render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
    end

    def update
      @meal_plan.update!(meal_plan_params)
      render json: meal_plan_json(@meal_plan.reload)
    rescue ActiveRecord::RecordInvalid => error
      render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
    end

    def destroy
      @meal_plan.destroy!
      head :no_content
    end

    private

    def set_meal_plan
      @meal_plan = MealPlan.find(params[:id])
    end

    def meal_plan_params
      params.require(:meal_plan).permit(:recipe_id, :planned_on, :meal_type, :servings, :notes)
    end

    def meal_plan_json(meal_plan)
      macros = macros_json(meal_plan.recipe.ingredients)
      meal_multiplier = meal_plan.servings.to_f / meal_plan.recipe.servings

      {
        id: meal_plan.id,
        planned_on: meal_plan.planned_on,
        meal_type: meal_plan.meal_type,
        servings: meal_plan.servings,
        notes: meal_plan.notes,
        macros: scaled_macros(macros, meal_multiplier),
        macros_per_serving: scaled_macros(macros, 1.0 / meal_plan.recipe.servings),
        recipe: {
          id: meal_plan.recipe.id,
          title: meal_plan.recipe.title,
          category: meal_plan.recipe.category,
          servings: meal_plan.recipe.servings,
          macros: macros,
          macros_per_serving: scaled_macros(macros, 1.0 / meal_plan.recipe.servings),
          ingredients: meal_plan.recipe.ingredients.sort_by(&:id).map do |ingredient|
            {
              id: ingredient.id,
              name: ingredient.name,
              quantity: ingredient.quantity.to_f,
              unit: ingredient.unit,
              calories: ingredient.calories.to_f,
              protein_grams: ingredient.protein_grams.to_f,
              carbs_grams: ingredient.carbs_grams.to_f,
              fat_grams: ingredient.fat_grams.to_f
            }
          end
        }
      }
    end

    def macros_json(ingredients)
      ingredients.each_with_object({
        calories: 0.0,
        protein_grams: 0.0,
        carbs_grams: 0.0,
        fat_grams: 0.0
      }) do |ingredient, totals|
        totals[:calories] += ingredient.calories.to_f
        totals[:protein_grams] += ingredient.protein_grams.to_f
        totals[:carbs_grams] += ingredient.carbs_grams.to_f
        totals[:fat_grams] += ingredient.fat_grams.to_f
      end
    end

    def scaled_macros(macros, multiplier)
      macros.transform_values { |value| (value * multiplier).round(1) }
    end
  end
end
