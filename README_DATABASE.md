# SkillMatch Database Setup

This document explains how to set up the local PostgreSQL database for the SkillMatch project.

## 1. Requirements

Before starting, install:

- PostgreSQL
- pgAdmin 4 (optional, but recommended)
- Go
- Git

Make sure PostgreSQL is running.

You can check PostgreSQL from PowerShell:

```powershell
psql --version
```

You can also check the PostgreSQL service:

```powershell
Get-Service *postgres*
```

The service status should be `Running`.

---

## 2. Database Structure

The main database schema is located here:

```text
database/skillmatch_schema.sql
```

This is the current database schema used by the Go backend.

The database contains the following main tables:

```text
users
student_profiles
companies
vacancies
skills
student_skills
vacancy_skills
applications
```

Important:

The backend uses the table:

```text
student_profiles
```

not the old temporary table:

```text
students
```

Also, the relation between a student and a skill uses:

```text
student_profile_id
```

inside the `student_skills` table.

---

## 3. Create the Database

Open PowerShell or the VS Code terminal.

Connect to PostgreSQL:

```powershell
psql -U postgres -h localhost -p 5432
```

Enter your PostgreSQL password.

After successful connection, you should see:

```text
postgres=#
```

Create the SkillMatch database:

```sql
CREATE DATABASE skillmatch;
```

Check that it exists:

```sql
\l
```

Exit PostgreSQL:

```sql
\q
```

---

## 4. Import the Database Schema

From the root folder of the SkillMatch project, run:

```powershell
psql -U postgres -h localhost -p 5432 -d skillmatch -f "database\skillmatch_schema.sql"
```

Enter your PostgreSQL password if requested.

If everything works correctly, PostgreSQL should create the project tables and indexes.

---

## 5. Verify the Tables

Connect to the SkillMatch database:

```powershell
psql -U postgres -h localhost -p 5432 -d skillmatch
```

Then run:

```sql
\dt
```

You should see tables such as:

```text
applications
companies
skills
student_profiles
student_skills
users
vacancies
vacancy_skills
```

Exit:

```sql
\q
```

---

## 6. Configure Backend Environment Variables

The Go backend uses a local `.env` file.

Go to:

```text
backend/
```

Create a file named:

```text
.env
```

Example:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=YOUR_POSTGRES_PASSWORD
DB_NAME=skillmatch
DB_SSLMODE=disable
```

Replace:

```text
YOUR_POSTGRES_PASSWORD
```

with your own PostgreSQL password.

Important:

Do not commit `.env` to Git because it contains local credentials.

The `.gitignore` file should contain:

```text
.env
```

---

## 7. Optional `.env.example`

The repository can contain a safe example configuration:

```text
backend/.env.example
```

Example content:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=skillmatch
DB_SSLMODE=disable
```

Each team member can copy this file and create their own `.env`.

---

## 8. Add Test User

To test the Student Profile API, first create a user.

Connect to the database:

```powershell
psql -U postgres -h localhost -p 5432 -d skillmatch
```

Then run:

```sql
INSERT INTO users (
    email,
    password_hash,
    role
)
VALUES (
    'student@test.com',
    'test_hash',
    'STUDENT'
);
```

Check the result:

```sql
SELECT * FROM users;
```

For a clean local database, the first user normally receives:

```text
id = 1
```

---

## 9. Add Test Student Profile

Create the student profile:

```sql
INSERT INTO student_profiles (
    user_id,
    full_name,
    university,
    major,
    education,
    experience_years
)
VALUES (
    1,
    'Kalikhan Arukhan',
    'Kazakh-British Technical University',
    'Information Systems',
    'Bachelor student',
    3.0
);
```

Check:

```sql
SELECT * FROM student_profiles;
```

For the current frontend and Postman tests, it is useful to have:

```text
student_profiles.id = 1
```

---

## 10. Add Test Skills

Add several skills:

```sql
INSERT INTO skills (name)
VALUES
    ('Flutter'),
    ('Go'),
    ('PostgreSQL'),
    ('Git'),
    ('REST API')
ON CONFLICT (name) DO NOTHING;
```

Check:

```sql
SELECT * FROM skills ORDER BY id;
```

---

## 11. Attach Skills to the Student

The `skills` table contains the list of available skills.

The `student_skills` table connects a skill to a particular student profile.

Example:

```sql
INSERT INTO student_skills (
    student_profile_id,
    skill_id,
    level
)
VALUES
    (1, 1, 'Intermediate'),
    (1, 2, 'Beginner'),
    (1, 3, 'Intermediate'),
    (1, 4, 'Intermediate'),
    (1, 5, 'Beginner')
ON CONFLICT DO NOTHING;
```

Check:

```sql
SELECT * FROM student_skills;
```

To see the skill names:

```sql
SELECT
    s.id,
    s.name,
    ss.level
FROM student_skills ss
JOIN skills s
    ON s.id = ss.skill_id
WHERE ss.student_profile_id = 1
ORDER BY s.name;
```

---

## 12. Run the Go Backend

Open a terminal:

```powershell
cd backend
```

Download Go dependencies if necessary:

```powershell
go mod download
```

Run the backend:

```powershell
go run ./cmd
```

If everything is configured correctly, you should see messages similar to:

```text
successfully connected to PostgreSQL
server started on http://localhost:8080
```

The backend is available at:

```text
http://localhost:8080
```

---

## 13. Basic API Tests

The API base path is:

```text
http://localhost:8080/api/v1
```

### Get Student Profile

```text
GET http://localhost:8080/api/v1/students/1
```

### Get Student Skills

```text
GET http://localhost:8080/api/v1/students/1/skills
```

### Add Student Skill

```text
POST http://localhost:8080/api/v1/students/1/skills
```

Body:

```json
{
  "name": "Docker"
}
```

This endpoint:

1. checks whether the skill already exists;
2. creates the skill if necessary;
3. attaches it to the student.

### Delete Student Skill

```text
DELETE http://localhost:8080/api/v1/students/1/skills?name=Docker
```

### Update Student Profile

```text
PUT http://localhost:8080/api/v1/students/1
```

Example body:

```json
{
  "full_name": "Kalikhan Arukhan",
  "university": "Kazakh-British Technical University",
  "major": "Information Systems",
  "education": "Bachelor student",
  "experience_years": 3.5
}
```

### Match Score

```text
GET http://localhost:8080/api/v1/students/1/vacancies/1/match
```

A company, vacancy and vacancy skills must exist before this endpoint can be tested properly.

---

## 14. Local Database Important Note

The PostgreSQL database is local.

This means:

```text
Your PostgreSQL database
≠
Your teammate's PostgreSQL database
```

When one team member inserts a student, skill or vacancy locally, these records are not automatically sent to GitHub.

Git stores files such as:

```text
skillmatch_schema.sql
main.go
README_DATABASE.md
```

Git does not store the actual contents of the running local PostgreSQL database.

Therefore, every team member needs to:

1. install PostgreSQL;
2. create the `skillmatch` database;
3. import `database/skillmatch_schema.sql`;
4. create their own `backend/.env`;
5. optionally load test data;
6. run the Go backend locally.

---

## 15. Recommended Test Data File

For easier team setup, it is recommended to create:

```text
database/seed.sql
```

The file can contain common development data such as:

- test student user;
- student profile;
- skills;
- company;
- vacancy;
- vacancy skills.

Then every team member can run:

```powershell
psql -U postgres -h localhost -p 5432 -d skillmatch -f "database\seed.sql"
```

This allows the whole team to use the same test data.

---

## 16. Files That Should Be Committed to Git

Recommended:

```text
database/skillmatch_schema.sql
database/seed.sql
README_DATABASE.md
backend/cmd/main.go
backend/.env.example
```

Do not commit:

```text
backend/.env
```

because it contains local PostgreSQL credentials.

---

## Current Status

The following local integration has been tested successfully:

```text
Postman
   ↓
Go Backend
   ↓
PostgreSQL
```

Tested functionality includes:

- retrieving a student profile;
- updating a student profile;
- retrieving student skills;
- creating a new skill;
- attaching a skill to a student;
- deleting a student skill;
- handling a non-existing student;
- calculating the vacancy match score.

The backend currently runs locally on:

```text
http://localhost:8080
```