class Recipe < ApplicationRecord
  has_many :ingredients, dependent: :destroy
  has_many :meal_plans, dependent: :destroy

  validates :title, presence: true
  validates :category, presence: true
  validates :prep_time_minutes, :cook_time_minutes, numericality: { greater_than_or_equal_to: 0 }
  validates :servings, numericality: { only_integer: true, greater_than: 0 }
end
