class Ingredient < ApplicationRecord
  belongs_to :recipe

  validates :name, :unit, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :calories, :protein_grams, :carbs_grams, :fat_grams,
    numericality: { greater_than_or_equal_to: 0 }
end
