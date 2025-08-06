# Task AI – Mobile Task Management App with AI Features

Task AI is a modern task management app built with Flutter. It allows users to manage their tasks and projects efficiently while integrating AI-powered task generation and smart suggestions to improve productivity.

## Features

### Core Features

- **Authentication**
  - Email & password login and registration
  - Basic input validation and error handling
  - Session persistence using `shared_preferences`

- **Projects & Tasks**
  - Create, edit, and delete Projects
  - Each project contains multiple Tasks
  - Task features:
    - Mark as complete/incomplete
    - Set priority: Low, Medium, High
    - Assign due dates

- **Dark/Light Mode**
  - Toggle between system, light, or dark theme
  - Theme saved using `shared_preferences`

- **Offline Support**
  - All data stored locally using `sqflite`
  - Local persistence and simulated backend sync using mock APIs and `Future.delayed`

---

## AI Assistant

### AI Task Assistant
- Prompts like _“Plan my week with 3 work tasks and 2 wellness tasks”_ generate suggested tasks
- Mock AI backend returns `AITaskSuggestion` items based on keyword parsing
- Users can:
  - Select which suggestions to import into any project
  - Remove or update individual suggestions
  - Rerun prompt with updated input

### Smart Task Rescheduler (Bonus)
- For overdue tasks, users can request an AI-suggested reschedule time
- AI simulates smart scheduling based on task priority and time of day

---

## Project Architecture

This app follows a scalable and modular structure:

