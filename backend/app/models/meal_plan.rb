class MealPlan < ApplicationRecord
  MEAL_TYPES = ["Breakfast", "Lunch", "Dinner", "Snack"].freeze

  belongs_to :recipe

  validates :planned_on, :meal_type, presence: true
  validates :meal_type, inclusion: { in: MEAL_TYPES }
  validates :servings, numericality: { only_integer: true, greater_than: 0 }
end
