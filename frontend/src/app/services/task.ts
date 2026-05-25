import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export type Task = {
  id: number;
  title: string;
  completed: boolean;
  created_at: string;
  updated_at: string;
};

type CreateTaskPayload = {
  title: string;
  completed?: boolean;
};

type UpdateTaskPayload = {
  title?: string;
  completed?: boolean;
};

@Injectable({
  providedIn: 'root'
})
export class TaskService {
  private readonly apiUrl = 'http://localhost:3000/api/tasks';

  constructor(private http: HttpClient) {}

  getTasks(): Observable<Task[]> {
    return this.http.get<Task[]>(this.apiUrl);
  }

  createTask(payload: CreateTaskPayload): Observable<Task> {
    return this.http.post<Task>(this.apiUrl, {
      task: payload
    });
  }

  updateTask(id: number, payload: UpdateTaskPayload): Observable<Task> {
    return this.http.patch<Task>(`${this.apiUrl}/${id}`, {
      task: payload
    });
  }

  deleteTask(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}