module Api
  class RecipesController < ApplicationController
    before_action :set_recipe, only: [:show, :update, :destroy]

    def index
      recipes = Recipe.includes(:ingredients).order(:title)
      render json: recipes.map { |recipe| recipe_json(recipe) }
    end

    def show
      render json: recipe_json(@recipe)
    end

    def create
      recipe = Recipe.new(recipe_attributes)

      Recipe.transaction do
        recipe.save!
        replace_ingredients(recipe)
      end

      render json: recipe_json(recipe.reload), status: :created
    rescue ActiveRecord::RecordInvalid => error
      render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
    end

    def update
      Recipe.transaction do
        @recipe.update!(recipe_attributes)
        replace_ingredients(@recipe) if params[:recipe].key?(:ingredients)
      end

      render json: recipe_json(@recipe.reload)
    rescue ActiveRecord::RecordInvalid => error
      render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
    end

    def destroy
      @recipe.destroy!
      head :no_content
    end

    private

    def set_recipe
      @recipe = Recipe.includes(:ingredients).find(params[:id])
    end

    def recipe_attributes
      params.require(:recipe).permit(:title, :description, :prep_time_minutes, :cook_time_minutes, :servings, :category)
    end

    def replace_ingredients(recipe)
      recipe.ingredients.destroy_all
      ingredients = params.require(:recipe).permit(
        ingredients: [:name, :quantity, :unit, :calories, :protein_grams, :carbs_grams, :fat_grams]
      )[:ingredients] || []

      ingredients.each do |ingredient|
        recipe.ingredients.create!(ingredient)
      end
    end

    def recipe_json(recipe)
      {
        id: recipe.id,
        title: recipe.title,
        description: recipe.description,
        prep_time_minutes: recipe.prep_time_minutes,
        cook_time_minutes: recipe.cook_time_minutes,
        servings: recipe.servings,
        category: recipe.category,
        macros: macros_json(recipe.ingredients),
        macros_per_serving: scaled_macros(macros_json(recipe.ingredients), 1.0 / recipe.servings),
        ingredients: recipe.ingredients.sort_by(&:id).map do |ingredient|
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
