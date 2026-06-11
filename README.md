# Smart Mess Food Management System 🍽️

A complete Flutter app for managing mess food selection, voting, and feedback.

## Project Structure

```
lib/
├── main.dart                    # App entry + Splash screen
├── theme.dart                   # Colors, theme, typography
├── models/
│   └── models.dart              # User, MealPoll, Vote, Feedback, KitchenOrder
├── services/
│   └── app_state.dart           # In-memory backend (no DB required)
├── widgets/
│   └── common_widgets.dart      # Reusable UI components
└── screens/
    ├── login_screen.dart         # Login for Student & Admin
    ├── student/
    │   ├── student_home_screen.dart  # Student dashboard + polls
    │   ├── vote_screen.dart          # Choose meal type & food option
    │   ├── feedback_screen.dart      # Rate meal after eating
    │   └── meal_history_screen.dart  # View finalized past meals
    └── admin/
        ├── admin_home_screen.dart    # Admin dashboard + stats
        ├── create_poll_screen.dart   # Create meal polls
        ├── poll_analysis_screen.dart # View vote counts & charts
        ├── kitchen_order_screen.dart # View finalized kitchen orders
        └── admin_feedback_screen.dart # Review student feedback
```

## Features

### Student Side
- Login with student credentials
- View active meal polls
- Vote for meal type (Veg / Non-Veg / Fast)
- Vote for specific food option within type
- Submit feedback with star ratings after meals
- View meal history

### Admin Side
- Login with admin credentials
- Dashboard with stats (active polls, students, votes, avg rating)
- Create meal polls with custom options for each type
- Analyze poll data with visual vote bars
- Finalize menu based on majority votes
- Send finalized counts + menu to kitchen
- Review student feedback with averages
- Improvement suggestions based on feedback

## Demo Credentials

| Role    | Email                | Password    |
|---------|----------------------|-------------|
| Student | pranav@mess.com      | student123  |
| Student | rohan@mess.com       | student123  |
| Admin   | admin@mess.com       | admin123    |

## How to Run

```bash
flutter pub get
flutter run
```

## Tech Stack
- Flutter (Dart)
- No external database (in-memory state)
- `intl` for date formatting
- `shared_preferences` (included for future persistence)
- Material 3 design

## Flow (matches flowchart)

```
Login Page
├── Student Login
│   ├── Choose Meal Type (Veg/Non-Veg/Fast)
│   ├── Vote for Food Option
│   └── Student Feedback
└── Admin Login
    ├── Create / Manage Meal Poll
    ├── Analyse Poll Data
    ├── Finalize Menu
    ├── Send Final Count to Kitchen
    ├── Review Student Feedback
    └── Improve Menu and Services
```
