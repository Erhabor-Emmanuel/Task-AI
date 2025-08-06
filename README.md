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
```
lib/
├── core/
│ └── theme_data.dart # Light/Dark theme setup
│
├── data/
│ ├── models/ # Task, Project, AITaskSuggestion, etc.
│ ├── providers/ # Provider-based state management
│ └── services/ # AIService, API simulation, and local storage
│
├── presentation/
│ ├── screens/ # Login, Dashboard, AIAssistantScreen, etc.
│ └── ui/ # Reusable widgets like AISuggestionCard
│
└── main.dart # App entry with routing and theme setup
```

-- Install Dependencies
```bash
flutter pub get
```
-- Run the App
```bash
flutter run
```

# AI Prompt Design, Fallback Strategies & Test Coverage
## Prompt Design
The AIService parses keywords from user prompts to generate realistic task suggestions in the following domains:

- Work/Productivity

- Health & Wellness

- Personal/Home Chores

- Learning & Study Tasks

- Prompts are validated and trimmed before dispatch. Sample prompts like:

“Create 5 tasks for my blog project”

“Plan a 3-day workout routine”
are encouraged through the ExamplePrompts UI.

## Fallback Strategies
- Error States: If the mock AI fails (10% simulated chance), an error message is shown with a retry option.

- Empty Results: If no suggestions match, the app gracefully informs the user.

- Invalid Prompts: Prompts under 5 or over 200 characters are rejected with user feedback.

- Offline Tasks: Tasks and projects remain accessible offline even if AI fails.

## Tech Stack
- Flutter

- Provider (state management)

- Sqflite (offline storage)

- Shared Preferences (theme + session persistence)

- Mock AI API (via Dart logic)


