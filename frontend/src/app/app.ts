import { Component, OnInit, computed, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { forkJoin } from 'rxjs';
import {
  Ingredient,
  MealPlan,
  Macros,
  Recipe,
  RecipePayload,
  RecipeService,
  ShoppingListItem
} from './services/recipe';

type RecipeForm = Omit<RecipePayload, 'ingredients'> & {
  id: number | null;
  ingredients: Ingredient[];
};

@Component({
  selector: 'app-root',
  imports: [FormsModule],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App implements OnInit {
  readonly mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  readonly weekDays = this.buildWeekDays();

  recipes = signal<Recipe[]>([]);
  mealPlans = signal<MealPlan[]>([]);
  shoppingList = signal<ShoppingListItem[]>([]);
  loading = signal(true);
  error = signal('');
  notice = signal('');

  recipeForm: RecipeForm = this.blankRecipeForm();
  mealPlanForm = {
    recipe_id: null as number | null,
    planned_on: this.todayIso(),
    meal_type: 'Dinner',
    servings: 2,
    notes: ''
  };

  totalRecipes = computed(() => this.recipes().length);
  plannedMealCount = computed(() => this.mealPlans().length);
  shoppingItemCount = computed(() => this.shoppingList().length);

  constructor(private recipeService: RecipeService) {}

  ngOnInit() {
    this.loadPlanner();
  }

  loadPlanner() {
    this.loading.set(true);
    this.error.set('');

    forkJoin({
      recipes: this.recipeService.getRecipes(),
      mealPlans: this.recipeService.getMealPlans(),
      shoppingList: this.recipeService.getShoppingList()
    }).subscribe({
      next: ({ recipes, mealPlans, shoppingList }) => {
        this.recipes.set(recipes);
        this.mealPlans.set(mealPlans);
        this.shoppingList.set(shoppingList);
        this.setDefaultRecipeForPlanning(recipes);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Could not load the meal planner. Make sure Rails is running on port 3000.');
        this.loading.set(false);
      }
    });
  }

  addIngredient() {
    this.recipeForm.ingredients = [
      ...this.recipeForm.ingredients,
      this.blankIngredient()
    ];
  }

  removeIngredient(index: number) {
    this.recipeForm.ingredients = this.recipeForm.ingredients.filter((_, currentIndex) => currentIndex !== index);
  }

  saveRecipe() {
    const payload = this.recipePayload();

    if (!payload) {
      return;
    }

    const request = this.recipeForm.id
      ? this.recipeService.updateRecipe(this.recipeForm.id, payload)
      : this.recipeService.createRecipe(payload);

    request.subscribe({
      next: (savedRecipe) => {
        this.recipes.update((recipes) => {
          const exists = recipes.some((recipe) => recipe.id === savedRecipe.id);
          return exists
            ? recipes.map((recipe) => recipe.id === savedRecipe.id ? savedRecipe : recipe)
            : [...recipes, savedRecipe].sort((left, right) => left.title.localeCompare(right.title));
        });
        this.setDefaultRecipeForPlanning(this.recipes());
        this.resetRecipeForm();
        this.error.set('');
        this.notice.set('Recipe saved.');
      },
      error: (err) => {
        this.error.set(this.errorMessage(err, 'Could not save recipe.'));
      }
    });
  }

  editRecipe(recipe: Recipe) {
    this.recipeForm = {
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      prep_time_minutes: recipe.prep_time_minutes,
      cook_time_minutes: recipe.cook_time_minutes,
      servings: recipe.servings,
      category: recipe.category,
      ingredients: recipe.ingredients.map((ingredient) => ({ ...ingredient }))
    };
    this.notice.set('');
  }

  resetRecipeForm() {
    this.recipeForm = this.blankRecipeForm();
  }

  deleteRecipe(recipeId: number) {
    this.recipeService.deleteRecipe(recipeId).subscribe({
      next: () => {
        this.recipes.update((recipes) => recipes.filter((recipe) => recipe.id !== recipeId));
        this.mealPlans.update((plans) => plans.filter((plan) => plan.recipe.id !== recipeId));
        this.refreshShoppingList();
        this.notice.set('Recipe removed.');
      },
      error: () => {
        this.error.set('Could not delete recipe.');
      }
    });
  }

  planMeal() {
    const recipeId = this.mealPlanForm.recipe_id;

    if (!recipeId) {
      this.error.set('Choose a recipe before adding it to the planner.');
      return;
    }

    this.recipeService.createMealPlan({
      recipe_id: recipeId,
      planned_on: this.mealPlanForm.planned_on,
      meal_type: this.mealPlanForm.meal_type,
      servings: this.mealPlanForm.servings,
      notes: this.mealPlanForm.notes
    }).subscribe({
      next: (mealPlan) => {
        this.mealPlans.update((mealPlans) =>
          [...mealPlans, mealPlan].sort((left, right) =>
            `${left.planned_on}${left.meal_type}`.localeCompare(`${right.planned_on}${right.meal_type}`)
          )
        );
        this.mealPlanForm.notes = '';
        this.refreshShoppingList();
        this.error.set('');
        this.notice.set('Meal added to the week.');
      },
      error: (err) => {
        this.error.set(this.errorMessage(err, 'Could not add meal to planner.'));
      }
    });
  }

  deleteMealPlan(mealPlanId: number) {
    this.recipeService.deleteMealPlan(mealPlanId).subscribe({
      next: () => {
        this.mealPlans.update((mealPlans) => mealPlans.filter((mealPlan) => mealPlan.id !== mealPlanId));
        this.refreshShoppingList();
      },
      error: () => {
        this.error.set('Could not remove planned meal.');
      }
    });
  }

  plansForDay(day: string) {
    return this.mealPlans().filter((mealPlan) => mealPlan.planned_on === day);
  }

  formatDay(day: string) {
    return new Intl.DateTimeFormat('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric'
    }).format(new Date(`${day}T12:00:00`));
  }

  formatQuantity(quantity: number) {
    return Number.isInteger(quantity) ? quantity.toString() : quantity.toFixed(2).replace(/0+$/, '').replace(/\.$/, '');
  }

  formatMacro(value: number) {
    return Math.round(value).toString();
  }

  macroItems(macros: Macros) {
    return [
      { label: 'Cal', value: this.formatMacro(macros.calories) },
      { label: 'Protein', value: `${this.formatMacro(macros.protein_grams)}g` },
      { label: 'Carbs', value: `${this.formatMacro(macros.carbs_grams)}g` },
      { label: 'Fat', value: `${this.formatMacro(macros.fat_grams)}g` }
    ];
  }

  totalMinutes(recipe: Recipe) {
    return recipe.prep_time_minutes + recipe.cook_time_minutes;
  }

  private refreshShoppingList() {
    this.recipeService.getShoppingList().subscribe({
      next: (shoppingList) => this.shoppingList.set(shoppingList),
      error: () => this.error.set('Could not refresh shopping list.')
    });
  }

  private recipePayload(): RecipePayload | null {
    const ingredients = this.recipeForm.ingredients
      .map((ingredient) => ({
        name: ingredient.name.trim(),
        quantity: Number(ingredient.quantity),
        unit: ingredient.unit.trim(),
        calories: Number(ingredient.calories),
        protein_grams: Number(ingredient.protein_grams),
        carbs_grams: Number(ingredient.carbs_grams),
        fat_grams: Number(ingredient.fat_grams)
      }))
      .filter((ingredient) => ingredient.name && ingredient.unit && ingredient.quantity > 0);

    const payload: RecipePayload = {
      title: this.recipeForm.title.trim(),
      description: this.recipeForm.description.trim(),
      prep_time_minutes: Number(this.recipeForm.prep_time_minutes),
      cook_time_minutes: Number(this.recipeForm.cook_time_minutes),
      servings: Number(this.recipeForm.servings),
      category: this.recipeForm.category.trim(),
      ingredients
    };

    if (!payload.title) {
      this.error.set('Recipe title is required.');
      return null;
    }

    if (!payload.category) {
      this.error.set('Category is required.');
      return null;
    }

    if (payload.servings < 1) {
      this.error.set('Servings must be at least 1.');
      return null;
    }

    if (!payload.ingredients.length) {
      this.error.set('Add at least one ingredient.');
      return null;
    }

    return payload;
  }

  private blankRecipeForm(): RecipeForm {
    return {
      id: null,
      title: '',
      description: '',
      prep_time_minutes: 10,
      cook_time_minutes: 20,
      servings: 4,
      category: 'Dinner',
      ingredients: [
        this.blankIngredient()
      ]
    };
  }

  private blankIngredient(): Ingredient {
    return {
      name: '',
      quantity: 1,
      unit: 'item',
      calories: 0,
      protein_grams: 0,
      carbs_grams: 0,
      fat_grams: 0
    };
  }

  private todayIso() {
    return new Date().toISOString().slice(0, 10);
  }

  private buildWeekDays() {
    const today = new Date();

    return Array.from({ length: 7 }, (_, index) => {
      const day = new Date(today);
      day.setDate(today.getDate() + index);
      return day.toISOString().slice(0, 10);
    });
  }

  private setDefaultRecipeForPlanning(recipes: Recipe[]) {
    if (!this.mealPlanForm.recipe_id && recipes.length) {
      this.mealPlanForm.recipe_id = recipes[0].id;
    }
  }

  private errorMessage(err: { error?: { errors?: string[] } }, fallback: string) {
    return err.error?.errors?.join(', ') || fallback;
  }
}
