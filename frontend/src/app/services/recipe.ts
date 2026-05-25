import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export type Ingredient = {
  id?: number;
  name: string;
  quantity: number;
  unit: string;
  calories: number;
  protein_grams: number;
  carbs_grams: number;
  fat_grams: number;
};

export type Macros = {
  calories: number;
  protein_grams: number;
  carbs_grams: number;
  fat_grams: number;
};

export type Recipe = {
  id: number;
  title: string;
  description: string;
  prep_time_minutes: number;
  cook_time_minutes: number;
  servings: number;
  category: string;
  macros: Macros;
  macros_per_serving: Macros;
  ingredients: Ingredient[];
};

export type RecipePayload = Omit<Recipe, 'id' | 'macros' | 'macros_per_serving'>;

export type MealPlan = {
  id: number;
  planned_on: string;
  meal_type: string;
  servings: number;
  notes: string | null;
  macros: Macros;
  macros_per_serving: Macros;
  recipe: Pick<Recipe, 'id' | 'title' | 'category' | 'servings' | 'ingredients' | 'macros' | 'macros_per_serving'>;
};

export type MealPlanPayload = {
  recipe_id: number;
  planned_on: string;
  meal_type: string;
  servings: number;
  notes?: string;
};

export type ShoppingListItem = {
  name: string;
  quantity: number;
  unit: string;
};

@Injectable({
  providedIn: 'root'
})
export class RecipeService {
  private readonly apiUrl = 'http://localhost:3000/api';

  constructor(private http: HttpClient) {}

  getRecipes(): Observable<Recipe[]> {
    return this.http.get<Recipe[]>(`${this.apiUrl}/recipes`);
  }

  createRecipe(payload: RecipePayload): Observable<Recipe> {
    return this.http.post<Recipe>(`${this.apiUrl}/recipes`, {
      recipe: payload
    });
  }

  updateRecipe(id: number, payload: RecipePayload): Observable<Recipe> {
    return this.http.patch<Recipe>(`${this.apiUrl}/recipes/${id}`, {
      recipe: payload
    });
  }

  deleteRecipe(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/recipes/${id}`);
  }

  getMealPlans(): Observable<MealPlan[]> {
    return this.http.get<MealPlan[]>(`${this.apiUrl}/meal_plans`);
  }

  createMealPlan(payload: MealPlanPayload): Observable<MealPlan> {
    return this.http.post<MealPlan>(`${this.apiUrl}/meal_plans`, {
      meal_plan: payload
    });
  }

  deleteMealPlan(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/meal_plans/${id}`);
  }

  getShoppingList(): Observable<ShoppingListItem[]> {
    return this.http.get<ShoppingListItem[]>(`${this.apiUrl}/shopping_list`);
  }
}
