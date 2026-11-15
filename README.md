# SkillMatch

**SkillMatch** is a cross-platform student internship and entry-level job matching platform built with **Flutter (Dart)**, **Go (REST API)**, and **PostgreSQL**. The platform connects students and partner companies through role-based workspaces, structured skill/language profiles, and real-time **AI Match Score** calculation.

---

## Project Architecture

```text
skillmatch_app/
├── backend/                     # Go REST API server (:8080, /api/v1)
├── database/                    # PostgreSQL schema & seed scripts
└── frontend/                    # Cross-platform Flutter app (Web, Android, iOS)
    └── lib/
        ├── core/                # AppTheme & cross-platform ApiConfig
        ├── models/              # Typed models: AuthSession, Vacancy, SkillItem, LanguageItem, StudentProfile
        ├── state/               # SessionController (ChangeNotifier + SharedPreferences persistence)
        ├── services/            # ApiClient, AuthService, StudentService, VacancyService
        ├── widgets/             # Reusable UI components (SkillChip, MatchScoreBadge)
        ├── screens/
        │   ├── auth/            # Responsive Login & Sign Up screen (Student / Company)
        │   ├── student/         # StudentShell, VacancyList, VacancyDetail, Profile, Courses/Events
        │   └── company/         # CompanyShell (Active Vacancies & Post Vacancy form)
        ├── api_service.dart     # Legacy compatibility re-export
        ├── screens.dart         # Legacy compatibility re-export
        └── main.dart            # App bootstrap, session restoration & role-based routing
```

---

## Key Features Implemented

* **Role-Based Authentication & Routing (`US9` / `T10`):** Responsive Login and Sign Up screen (two-column split-screen on Web, compact card on Mobile) with role switching (`STUDENT` / `COMPANY`), credential validation, and isolated workspaces (`StudentShell` vs. `CompanyShell`).
* **Persistent Session & Route Restoration:** Uses `shared_preferences` (`localStorage` on Web, native storage on Android/iOS) so refreshing the browser (`F5`) or restarting the app keeps the user signed in on the exact active tab or vacancy details page.
* **Skill Levels & Real-Time AI Match Score (`I-01` / `T12`):** Students add skills with proficiency levels (`Beginner`, `Intermediate`, `Advanced`). Vacancy detail screens calculate match percentage in real time and highlight matched skills in green and missing skills in orange.
* **Student Languages Section:** Students can manage spoken languages (`English`, `Russian`, `Kazakh`, `Chinese`, etc.) with CEFR levels (`A1`–`C2` / `Native`) and verification status badges.
* **Company Workspace (`T11` / `US10`):** Companies can view active openings and publish new vacancies directly to the student feed.

---

## Database Setup (PostgreSQL)

1. Ensure PostgreSQL is running and the `skillmatch` database is initialized with the base 8 tables (`users`, `student_profiles`, `companies`, `skills`, `student_skills`, `vacancies`, `vacancy_skills`, `applications`).
2. Run the additive migration below to add support for the new **Student Languages** table (non-breaking — existing tables remain untouched):

```sql
CREATE TABLE IF NOT EXISTS student_languages (
    id SERIAL PRIMARY KEY,
    student_profile_id INT NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    language_name VARCHAR(100) NOT NULL,
    proficiency_level VARCHAR(50) NOT NULL,
    verification_status VARCHAR(30) NOT NULL DEFAULT 'UNVERIFIED',
    certificate_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_profile_id, language_name)
);
```

---

## Running the Project Locally

### 1. Start the Go Backend (Windows & macOS)

Open **Terminal 1**:

```bash
cd backend
go mod tidy
go run ./cmd
```

The API server starts on `http://localhost:8080/api/v1`.

---

### 2. Run Flutter Frontend on Windows

#### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (3.x+)
* Google Chrome (for Web) and/or Android Studio with Android SDK & Emulator (for Android)

Open **Terminal 2**:

```powershell
cd frontend
flutter pub get
```

* **Run in Web (Chrome):**
  ```powershell
  flutter run -d chrome
  ```
* **Run on Android Emulator:**
  1. Launch an emulator via Android Studio or CLI:
     ```powershell
     flutter emulators
     flutter emulators --launch <emulator_id>
     ```
  2. Run the app (automatically routes API requests to `http://10.0.2.2:8080/api/v1`):
     ```powershell
     flutter run -d android
     ```

---

### 3. Run Flutter Frontend on macOS (Chrome, Android Emulator, and Xcode / iOS Simulator)

#### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install/macos) (3.x+)
* **Xcode** (from the Mac App Store) + Xcode Command Line Tools + **CocoaPods** (`brew install cocoapods`)
* Google Chrome / Android Studio (optional for Web & Android testing)

Open **Terminal 2**:

```bash
cd frontend
flutter pub get
```

* **Run in Xcode / iOS Simulator:**
  1. Install iOS native pods (required after adding `shared_preferences`):
     ```bash
     cd ios
     pod install
     cd ..
     ```
  2. Open the iOS Simulator:
     ```bash
     open -a Simulator
     ```
  3. Launch the app (automatically routes API requests to `http://localhost:8080/api/v1`):
     ```bash
     flutter run
     ```
  *(To inspect or sign builds directly in Xcode, open `frontend/ios/Runner.xcworkspace`.)*

* **Run in Web (Chrome) on macOS:**
  ```bash
  flutter run -d chrome
  ```

---

## API Contract & Team Integration Endpoints

| Feature | Method & Endpoint | Payload / Response Notes |
| :--- | :--- | :--- |
| **Login (`T9`/`T10`)** | `POST /api/v1/auth/login` | Body: `{ "email", "password" }` $\rightarrow$ Returns `{ "token", "role", "user_id", "student_profile_id" / "company_id" }` |
| **Register (`T9`/`T10`)** | `POST /api/v1/auth/register` | Body: `{ "email", "password", "role": "STUDENT" \| "COMPANY", "full_name" / "company_name" }` |
| **Vacancies + Match** | `GET /api/v1/vacancies?student_id=:id` | Returns vacancy list with computed `match_score` |
| **Create Vacancy (`T11`)** | `POST /api/v1/vacancies` | Body: `{ "company_id", "title", "description", "experience_required", "employment_type", "location", "skills": [...] }` |
| **Add Student Skill (`T12`)** | `POST /api/v1/students/:id/skills` | Body: `{ "skill_name", "level": "Beginner" \| "Intermediate" \| "Advanced" }` |

> **QA / Demo Mode (`T13`):** On the Login screen, use **Demo Student** or **Demo Company** buttons for instant one-click role testing, or enter password `wrong` to verify invalid-credential rejection.