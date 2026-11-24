package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"math"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
	"unicode"

	"github.com/gin-gonic/gin"
	"github.com/jmoiron/sqlx"
	"github.com/joho/godotenv"

	"skillmatch-backend/internal/database"
	"skillmatch-backend/internal/handler"
	"skillmatch-backend/internal/repository"
	"skillmatch-backend/internal/service"
)

type SkillCatalogItem struct {
	ID       int64  `json:"id"`
	Name     string `json:"name"`
	Category string `json:"category"`
}

type StudentSkillItem struct {
	ID       int64  `json:"id"`
	Name     string `json:"name"`
	Category string `json:"category"`
	Level    string `json:"level"`
}

type SkillRequest struct {
	Name  string `json:"name"`
	Level string `json:"level"`
}

type StudentProfilePayload struct {
	ID              int64   `json:"id"`
	UserID          int64   `json:"user_id"`
	FullName        string  `json:"full_name"`
	University      string  `json:"university"`
	Major           string  `json:"major"`
	ExperienceYears float64 `json:"experience_years"`
	Bio             string  `json:"bio"`
	TargetRole      string  `json:"target_role"`
	GithubURL       string  `json:"github_url"`
	LinkedinURL     string  `json:"linkedin_url"`
	IsAdmin         bool    `json:"is_admin"`
}

type VacancyResponse struct {
	ID                 int64    `json:"id"`
	CompanyID          int64    `json:"company_id"`
	CompanyName        string   `json:"company_name"`
	Title              string   `json:"title"`
	Description        string   `json:"description"`
	ExperienceRequired float64  `json:"experience_required"`
	EmploymentType     string   `json:"employment_type"`
	WorkFormat         string   `json:"work_format"`
	Location           string   `json:"location"`
	SalaryRange        string   `json:"salary_range"`
	IsActive           bool     `json:"is_active"`
	ApplicantsCount    int      `json:"applicants_count"`
	NewApplicantsCount int      `json:"new_applicants_count"`
	ApplicationID      int64    `json:"application_id"`
	AppliedStatus      string   `json:"applied_status"`
	CoverLetter        string   `json:"cover_letter"`
	CompanyFeedback    string   `json:"company_feedback"`
	Skills             []string `json:"skills"`
	MatchScore         int      `json:"match_score"`
	MatchedSkills      []string `json:"matched_skills"`
	MissingSkills      []string `json:"missing_skills"`
}

type CreateVacancyRequest struct {
	CompanyID          int64    `json:"company_id"`
	Title              string   `json:"title"`
	Description        string   `json:"description"`
	EmploymentType     string   `json:"employment_type"`
	WorkFormat         string   `json:"work_format"`
	Location           string   `json:"location"`
	ExperienceRequired int      `json:"experience_required"`
	SalaryRange        string   `json:"salary_range"`
	Skills             []string `json:"skills"`
}

type AuthRequest struct {
	Email           string  `json:"email"`
	Password        string  `json:"password"`
	Role            string  `json:"role"`
	Name            string  `json:"name"`
	University      string  `json:"university"`
	Major           string  `json:"major"`
	ExperienceYears float64 `json:"experience_years"`
	Description     string  `json:"description"`
}

type LanguageItem struct {
	ID               int64  `json:"id"`
	StudentProfileID int64  `json:"student_profile_id"`
	LanguageName     string `json:"language_name"`
	CefrLevel        string `json:"cefr_level"`
	ProficiencyLevel string `json:"proficiency_level"`
}

type AddLanguageRequest struct {
	LanguageName     string `json:"language_name"`
	CefrLevel        string `json:"cefr_level"`
	ProficiencyLevel string `json:"proficiency_level"`
}

type CompanyApplicantItem struct {
	ApplicationID    int64              `json:"application_id"`
	VacancyID        int64              `json:"vacancy_id"`
	VacancyTitle     string             `json:"vacancy_title"`
	StudentProfileID int64              `json:"student_profile_id"`
	StudentName      string             `json:"student_name"`
	StudentEmail     string             `json:"student_email"`
	University       string             `json:"university"`
	Major            string             `json:"major"`
	ExperienceYears  float64            `json:"experience_years"`
	TargetRole       string             `json:"target_role"`
	Bio              string             `json:"bio"`
	GithubURL        string             `json:"github_url"`
	LinkedinURL      string             `json:"linkedin_url"`
	MatchScore       int                `json:"match_score"`
	Status           string             `json:"status"`
	CoverLetter      string             `json:"cover_letter"`
	CompanyFeedback  string             `json:"company_feedback"`
	AppliedAt        string             `json:"applied_at"`
	UpdatedAt        string             `json:"updated_at"`
	StudentSkills    []StudentSkillItem `json:"student_skills"`
	StudentLanguages []LanguageItem     `json:"student_languages"`
	MatchedSkills    []string           `json:"matched_skills"`
	MissingSkills    []string           `json:"missing_skills"`
	RegisteredEvents []string           `json:"registered_events"`
}

type EventItem struct {
	ID              int64    `json:"id"`
	CompanyID       int64    `json:"company_id"`
	Title           string   `json:"title"`
	Organizer       string   `json:"organizer"`
	EventType       string   `json:"event_type"`
	EventDate       string   `json:"event_date"`
	Location        string   `json:"location"`
	WorkFormat      string   `json:"work_format"`
	Capacity        int      `json:"capacity"`
	ExternalURL     string   `json:"external_url"`
	Description     string   `json:"description"`
	Tags            string   `json:"tags"`
	RegisteredCount int      `json:"registered_count"`
	IsRegistered    bool     `json:"is_registered"`
	IsRecommended   bool     `json:"is_recommended"`
	MatchedTags     []string `json:"matched_tags"`
}

type CourseItem struct {
	ID                    int64  `json:"id"`
	CompanyID             int64  `json:"company_id"`
	Title                 string `json:"title"`
	Provider              string `json:"provider"`
	SkillName             string `json:"skill_name"`
	Level                 string `json:"level"`
	Language              string `json:"language"`
	Duration              string `json:"duration"`
	IsFree                bool   `json:"is_free"`
	ExternalURL           string `json:"external_url"`
	Description           string `json:"description"`
	EnrollmentStatus      string `json:"enrollment_status"`
	IsRecommended         bool   `json:"is_recommended"`
	RecommendationReason  string `json:"recommendation_reason"`
	BoostedVacanciesCount int    `json:"boosted_vacancies_count"`
}

func skillWeight(level string) float64 {
	switch strings.ToLower(strings.TrimSpace(level)) {
	case "beginner":
		return 1
	case "intermediate":
		return 2
	case "advanced":
		return 3
	default:
		return 2
	}
}

func detectLanguage(text string) string {
	for _, r := range text {
		if unicode.Is(unicode.Cyrillic, r) {
			return "RU"
		}
	}
	return "EN"
}

type stepikCoursesResponse struct {
	Courses []struct {
		ID           int64  `json:"id"`
		Title        string `json:"title"`
		Summary      string `json:"summary"`
		IsPaid       bool   `json:"is_paid"`
		CanonicalURL string `json:"canonical_url"`
	} `json:"courses"`
}

// fetchAndCacheLiveCourses подтягивает бесплатные курсы из Stepik API + Coursera/roadmap.sh
// и сохраняет их в таблицу courses (кэш в Neon PostgreSQL)
func fetchAndCacheLiveCourses(db *sqlx.DB, skill string) {
	cleanSkill := strings.TrimSpace(skill)
	if cleanSkill == "" {
		return
	}

	endpoint := "https://stepik.org/api/courses?search=" + url.QueryEscape(cleanSkill) + "&is_public=true"
	client := &http.Client{Timeout: 4 * time.Second}
	resp, err := client.Get(endpoint)

	inserted := 0
	if err == nil && resp.StatusCode == 200 {
		defer resp.Body.Close()
		var parsed stepikCoursesResponse
		if json.NewDecoder(resp.Body).Decode(&parsed) == nil {
			for _, c := range parsed.Courses {
				if c.IsPaid || strings.TrimSpace(c.Title) == "" {
					continue
				}
				link := strings.TrimSpace(c.CanonicalURL)
				if link == "" {
					link = "https://stepik.org/course/" + strconv.FormatInt(c.ID, 10) + "/promo"
				}
				desc := strings.TrimSpace(c.Summary)
				if desc == "" {
					desc = "Бесплатный практический курс по " + cleanSkill + " на платформе Stepik."
				}
				lang := detectLanguage(c.Title + " " + desc)
				_, err := db.Exec(`
					INSERT INTO courses (company_id, title, provider, skill_name, level, language, duration, is_free, external_url, description)
					VALUES (0, $1, 'Stepik', $2, 'Intermediate', $3, 'Self-paced', TRUE, $4, $5)
					ON CONFLICT (title) DO NOTHING
				`, strings.TrimSpace(c.Title), cleanSkill, lang, link, desc)
				if err == nil {
					inserted++
				}
				if inserted >= 2 {
					break
				}
			}
		}
	}

	// Дополняем прямыми бесплатными материалами Coursera и roadmap.sh, чтобы у студента всегда было 2-3 варианта
	q := url.QueryEscape(cleanSkill)
	slug := strings.ToLower(strings.ReplaceAll(cleanSkill, " ", "-"))
	fallbacks := []struct {
		title    string
		provider string
		level    string
		lang     string
		duration string
		link     string
		desc     string
	}{
		{
			title:    cleanSkill + " — Free Courses & Hands-on Labs",
			provider: "Coursera",
			level:    "Intermediate",
			lang:     "EN",
			duration: "2-4 weeks",
			link:     "https://www.coursera.org/courses?query=" + q,
			desc:     "Бесплатные курсы и практические лаборатории от университетов и IT-компаний по " + cleanSkill + ".",
		},
		{
			title:    cleanSkill + " — Interactive Developer Roadmap & Guides",
			provider: "roadmap.sh",
			level:    "Beginner",
			lang:     "EN",
			duration: "Self-paced",
			link:     "https://roadmap.sh/" + slug,
			desc:     "Пошаговая карта изучения " + cleanSkill + " с бесплатными статьями, документацией и практическими чек-листами.",
		},
	}

	for _, fb := range fallbacks {
		_, _ = db.Exec(`
			INSERT INTO courses (company_id, title, provider, skill_name, level, language, duration, is_free, external_url, description)
			VALUES (0, $1, $2, $3, $4, $5, $6, TRUE, $7, $8)
			ON CONFLICT (title) DO NOTHING
		`, fb.title, fb.provider, cleanSkill, fb.level, fb.lang, fb.duration, fb.link, fb.desc)
	}
}

func ensureSchemaAndSkills(db *sqlx.DB) {
	migrations := []string{
		`ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE`,
		`ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT ''`,
		`ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS target_role VARCHAR(150) DEFAULT 'Software Engineering Intern'`,
		`ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS github_url TEXT DEFAULT ''`,
		`ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS linkedin_url TEXT DEFAULT ''`,
		`ALTER TABLE vacancies ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE`,
		`ALTER TABLE applications ADD COLUMN IF NOT EXISTS cover_letter TEXT DEFAULT ''`,
		`ALTER TABLE applications ADD COLUMN IF NOT EXISTS company_feedback TEXT DEFAULT ''`,
		`ALTER TABLE applications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`,
		`DO $$
		BEGIN
			IF NOT EXISTS (
				SELECT 1 FROM pg_constraint WHERE conname = 'applications_vacancy_student_unique'
			) THEN
				ALTER TABLE applications
				ADD CONSTRAINT applications_vacancy_student_unique UNIQUE (vacancy_id, student_profile_id);
			END IF;
		EXCEPTION WHEN others THEN
			NULL;
		END $$;`,
		`CREATE TABLE IF NOT EXISTS events (
			id SERIAL PRIMARY KEY,
			company_id INT DEFAULT 0,
			title VARCHAR(200) NOT NULL UNIQUE,
			organizer VARCHAR(150) NOT NULL,
			event_type VARCHAR(80) DEFAULT 'Tech Meetup',
			event_date VARCHAR(100) NOT NULL,
			location VARCHAR(150) DEFAULT 'Almaty',
			work_format VARCHAR(50) DEFAULT 'Offline',
			capacity INT DEFAULT 100,
			external_url TEXT DEFAULT '',
			description TEXT DEFAULT '',
			tags VARCHAR(250) DEFAULT ''
		)`,
		`ALTER TABLE events ADD COLUMN IF NOT EXISTS company_id INT DEFAULT 0`,
		`ALTER TABLE events ADD COLUMN IF NOT EXISTS capacity INT DEFAULT 100`,
		`ALTER TABLE events ADD COLUMN IF NOT EXISTS external_url TEXT DEFAULT ''`,
		`CREATE TABLE IF NOT EXISTS event_registrations (
			id SERIAL PRIMARY KEY,
			event_id INT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
			student_profile_id INT NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
			registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(event_id, student_profile_id)
		)`,
		`CREATE TABLE IF NOT EXISTS courses (
			id SERIAL PRIMARY KEY,
			company_id INT DEFAULT 0,
			title VARCHAR(200) NOT NULL UNIQUE,
			provider VARCHAR(120) NOT NULL,
			skill_name VARCHAR(100) NOT NULL,
			level VARCHAR(50) DEFAULT 'Intermediate',
			language VARCHAR(20) DEFAULT 'RU',
			duration VARCHAR(60) DEFAULT '4 weeks',
			is_free BOOLEAN DEFAULT TRUE,
			external_url TEXT DEFAULT '',
			description TEXT DEFAULT ''
		)`,
		`ALTER TABLE courses ADD COLUMN IF NOT EXISTS company_id INT DEFAULT 0`,
		`ALTER TABLE courses ADD COLUMN IF NOT EXISTS language VARCHAR(20) DEFAULT 'RU'`,
		`ALTER TABLE courses ADD COLUMN IF NOT EXISTS external_url TEXT DEFAULT ''`,
		`CREATE TABLE IF NOT EXISTS student_courses (
			id SERIAL PRIMARY KEY,
			course_id INT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
			student_profile_id INT NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
			status VARCHAR(50) DEFAULT 'Enrolled',
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(course_id, student_profile_id)
		)`,
	}
	for _, m := range migrations {
		if _, err := db.Exec(m); err != nil {
			log.Println("migration notice:", err)
		}
	}

	// Выдаём права администратора роли ADMIN и аккаунту Жумабека
	_, _ = db.Exec(`
		UPDATE users
		SET is_admin = TRUE
		WHERE role = 'ADMIN'
		   OR id IN (
		       SELECT user_id FROM student_profiles
		       WHERE LOWER(full_name) LIKE '%zhumabek%' OR LOWER(full_name) LIKE '%жұмабек%' OR LOWER(full_name) LIKE '%жумабек%'
		   )
	`)

	seedSkillsSQL := `
	INSERT INTO skills (name, category) VALUES
	('Go', 'Backend'), ('Python', 'Backend'), ('Java', 'Backend'), ('Spring Boot', 'Backend'),
	('Node.js', 'Backend'), ('Express.js', 'Backend'), ('NestJS', 'Backend'), ('C#', 'Backend'),
	('.NET Core', 'Backend'), ('PHP', 'Backend'), ('Laravel', 'Backend'), ('Ruby on Rails', 'Backend'),
	('FastAPI', 'Backend'), ('Django', 'Backend'), ('Flask', 'Backend'), ('REST API', 'Backend'),
	('GraphQL', 'Backend'), ('gRPC', 'Backend'), ('Microservices', 'Backend'), ('Kafka', 'Backend'),
	('RabbitMQ', 'Backend'),
	('JavaScript', 'Frontend'), ('TypeScript', 'Frontend'), ('React', 'Frontend'), ('Next.js', 'Frontend'),
	('Vue.js', 'Frontend'), ('Nuxt.js', 'Frontend'), ('Angular', 'Frontend'), ('HTML5', 'Frontend'),
	('CSS3', 'Frontend'), ('Tailwind CSS', 'Frontend'), ('Redux', 'Frontend'),
	('Flutter', 'Mobile'), ('Dart', 'Mobile'), ('Kotlin', 'Mobile'), ('Android SDK', 'Mobile'),
	('Swift', 'Mobile'), ('SwiftUI', 'Mobile'), ('React Native', 'Mobile'), ('Firebase', 'Mobile'),
	('PostgreSQL', 'Database'), ('MySQL', 'Database'), ('SQL', 'Database'), ('MongoDB', 'Database'),
	('Redis', 'Database'), ('SQLite', 'Database'), ('Elasticsearch', 'Database'), ('ClickHouse', 'Database'),
	('Docker', 'DevOps'), ('Kubernetes', 'DevOps'), ('Linux', 'DevOps'), ('Git', 'DevOps'),
	('GitHub Actions', 'DevOps'), ('CI/CD', 'DevOps'), ('AWS', 'DevOps'), ('Google Cloud', 'DevOps'),
	('Nginx', 'DevOps'), ('Terraform', 'DevOps'),
	('Data Analysis', 'Data & AI'), ('Pandas', 'Data & AI'), ('NumPy', 'Data & AI'),
	('Machine Learning', 'Data & AI'), ('Deep Learning', 'Data & AI'), ('PyTorch', 'Data & AI'),
	('TensorFlow', 'Data & AI'), ('Scikit-learn', 'Data & AI'), ('Computer Vision', 'Data & AI'),
	('NLP', 'Data & AI'), ('LLM & Prompt Engineering', 'Data & AI'), ('Power BI', 'Data & AI'),
	('Tableau', 'Data & AI'), ('Apache Spark', 'Data & AI'),
	('Figma', 'Design & Product'), ('UI/UX Design', 'Design & Product'), ('Prototyping', 'Design & Product'),
	('Design Systems', 'Design & Product'), ('Product Management', 'Design & Product'),
	('Agile / Scrum', 'Design & Product'), ('Jira', 'Design & Product'),
	('Manual QA', 'QA & Security'), ('Automated Testing', 'QA & Security'), ('Selenium', 'QA & Security'),
	('Playwright', 'QA & Security'), ('Postman', 'QA & Security'), ('Cybersecurity', 'QA & Security'),
	('Network Security', 'QA & Security')
	ON CONFLICT (name) DO UPDATE SET category = EXCLUDED.category;
	`
	_, _ = db.Exec(seedSkillsSQL)

	seedEventsSQL := `
	INSERT INTO events (company_id, title, organizer, event_type, event_date, location, work_format, capacity, external_url, description, tags) VALUES
	(
		0,
		'IT-беш Servercore: AI-инфраструктура и GPU',
		'Servercore',
		'Tech Meetup',
		TO_CHAR(CURRENT_DATE + INTERVAL '2 days', 'YYYY-MM-DD') || ' • 19:00',
		'Almaty',
		'Offline',
		80,
		'https://choyxona.tech/en/events/almaty/',
		'Практический вечерний митап об архитектуре AI-инфраструктуры, облачных вычислениях и работе с GPU-кластерами в продакшене.',
		'AI, GPU, Cloud, DevOps, Linux'
	),
	(
		0,
		'Запуск национальной платформы PROVECTOR: переход в финтех',
		'PROVECTOR Community',
		'Product Launch',
		TO_CHAR(CURRENT_DATE + INTERVAL '3 days', 'YYYY-MM-DD') || ' • 18:30',
		'Almaty',
		'Offline',
		120,
		'https://choyxona.tech/en/events/almaty/',
		'Презентация национальной карьерной платформы для специалистов и студентов, планирующих старт и переход в финтех-индустрию Казахстана.',
		'Fintech, Product Management, Career, Agile / Scrum'
	),
	(
		0,
		'Саммит CDO ExecLeaders: от ИИ-пилотов к масштабированию',
		'CDO ExecLeaders',
		'Conference',
		TO_CHAR(CURRENT_DATE + INTERVAL '5 days', 'YYYY-MM-DD') || ' • 10:00',
		'Almaty',
		'Offline',
		150,
		'https://choyxona.tech/en/events/almaty/',
		'Отраслевой саммит руководителей по данным и ИИ: кейсы внедрения ML-моделей, аналитики данных и масштабирования AI-сервисов в компаниях.',
		'Data Analysis, Machine Learning, LLM & Prompt Engineering, Python'
	),
	(
		0,
		'Митап BCC HUB по системному анализу с реальными кейсами',
		'BCC HUB (Банк ЦентрКредит)',
		'Tech Meetup',
		TO_CHAR(CURRENT_DATE + INTERVAL '6 days', 'YYYY-MM-DD') || ' • 14:00',
		'Almaty, BCC HUB',
		'Offline',
		100,
		'https://choyxona.tech/en/events/almaty/',
		'Бесплатный разбор реальных банковских кейсов по системному анализу, проектированию REST API, работе с базами данных и интеграциям.',
		'REST API, SQL, PostgreSQL, Product Management'
	),
	(
		0,
		'AI for Business от nFactorial School',
		'nFactorial School',
		'Workshop',
		TO_CHAR(CURRENT_DATE + INTERVAL '8 days', 'YYYY-MM-DD') || ' • 15:00',
		'Almaty',
		'Offline',
		90,
		'https://choyxona.tech/en/events/almaty/',
		'Практический тренинг от nFactorial School по применению генеративного ИИ и LLM-инструментов для автоматизации продуктовых и инженерных задач.',
		'LLM & Prompt Engineering, Python, FastAPI, AI'
	),
	(
		0,
		'Студенческий хакатон AI Engineering Almaty',
		'AI Engineering Almaty',
		'Hackathon',
		TO_CHAR(CURRENT_DATE + INTERVAL '10 days', 'YYYY-MM-DD') || ' • 10:00',
		'Almaty',
		'Offline',
		120,
		'https://choyxona.tech/en/events/almaty/',
		'Командный студенческий хакатон по созданию рабочих прототипов ИИ-решений с менторской поддержкой инженеров и питчингом проектов.',
		'Python, Machine Learning, FastAPI, Docker, Git'
	)
	ON CONFLICT (title) DO NOTHING;
	`
	_, _ = db.Exec(seedEventsSQL)

	seedCoursesSQL := `
	INSERT INTO courses (company_id, title, provider, skill_name, level, language, duration, is_free, external_url, description) VALUES
	(0, 'Программирование на Golang', 'Stepik', 'Go', 'Beginner', 'RU', '1 week', TRUE, 'https://stepik.org/course/54403/promo', 'Интенсивный практический курс по синтаксису Go, структурам данных, горутинам, интерфейсам и стандартной библиотеке с автоматической проверкой кода.'),
	(0, 'Введение в язык программирования Go (Golang)', 'Stepik', 'Go', 'Intermediate', 'RU', '3 weeks', TRUE, 'https://stepik.org/course/172812/promo', 'Углублённая практика по слайсам, мапам, обработке ошибок, конкурентности и идиоматичному проектированию сервисов на Go.'),
	(0, 'Знакомство с Docker', 'Stepik', 'Docker', 'Beginner', 'RU', '2 weeks', TRUE, 'https://stepik.org/catalog/search?free=true&q=Docker', 'Практика упаковки приложений в контейнеры с нуля: работа с Docker CLI, написание Dockerfile, сборка образов и оркестрация через Docker Compose.'),
	(0, 'Introduction to Docker', 'Coursera', 'Docker', 'Intermediate', 'EN', '1 week', TRUE, 'https://www.coursera.org/courses?query=docker', 'Лабораторный курс от Google Cloud по созданию, отладке и публикации контейнерных образов для облачного деплоя микросервисов.'),
	(0, 'Database Design and Basic SQL in PostgreSQL', 'Coursera', 'PostgreSQL', 'Intermediate', 'EN', '2 weeks', TRUE, 'https://www.coursera.org/learn/database-design-postgresql', 'Курс University of Michigan по проектированию реляционных схем, нормализации, внешним ключам и сложным SQL-запросам в PostgreSQL.'),
	(0, 'Симулятор SQL', 'karpov.courses', 'SQL', 'Intermediate', 'RU', '4 weeks', TRUE, 'https://karpov.courses', 'Интерактивный тренажёр с реальными продуктовыми и аналитическими задачами: JOIN, агрегации, подзапросы и оконные функции.'),
	(0, 'Introduction to Containers w/ Docker, Kubernetes & OpenShift', 'Coursera', 'Kubernetes', 'Intermediate', 'EN', '4 weeks', TRUE, 'https://www.coursera.org/courses?query=kubernetes', 'Практический курс от IBM по развёртыванию контейнеров, управлению кластерами Kubernetes, Pods, Services и масштабированию приложений.'),
	(0, 'Introduction to Front-End Development', 'Coursera', 'React', 'Beginner', 'EN', '3 weeks', TRUE, 'https://www.coursera.org/courses?query=react', 'Официальный курс от инженеров Meta по современной веб-разработке, компонентному подходу, UI-вёрстке и основам React.'),
	(0, 'Databases and SQL for Data Science with Python', 'Coursera', 'Python', 'Intermediate', 'EN', '4 weeks', TRUE, 'https://www.coursera.org/courses?query=python+sql', 'Работа с реляционными базами данных из Python, написание аналитических SQL-запросов и интеграция данных в ML-пайплайны.'),
	(0, 'Flutter Разработка. От базы до вайб кодинга', 'Stepik', 'Flutter', 'Intermediate', 'RU', '4 weeks', FALSE, 'https://stepik.org/course/208780/promo', 'Кроссплатформенная разработка на Dart и Flutter: архитектура виджетов, работа с REST API, локальным состоянием и сборка под Web и Mobile.')
	ON CONFLICT (title) DO NOTHING;
	`
	_, _ = db.Exec(seedCoursesSQL)

	sequences := []string{
		`SELECT setval(pg_get_serial_sequence('users', 'id'), COALESCE((SELECT MAX(id) FROM users), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('student_profiles', 'id'), COALESCE((SELECT MAX(id) FROM student_profiles), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('companies', 'id'), COALESCE((SELECT MAX(id) FROM companies), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('skills', 'id'), COALESCE((SELECT MAX(id) FROM skills), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('student_skills', 'id'), COALESCE((SELECT MAX(id) FROM student_skills), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('student_languages', 'id'), COALESCE((SELECT MAX(id) FROM student_languages), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('vacancies', 'id'), COALESCE((SELECT MAX(id) FROM vacancies), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('vacancy_skills', 'id'), COALESCE((SELECT MAX(id) FROM vacancy_skills), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('applications', 'id'), COALESCE((SELECT MAX(id) FROM applications), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('events', 'id'), COALESCE((SELECT MAX(id) FROM events), 0) + 1, false)`,
		`SELECT setval(pg_get_serial_sequence('courses', 'id'), COALESCE((SELECT MAX(id) FROM courses), 0) + 1, false)`,
	}
	for _, seq := range sequences {
		_, _ = db.Exec(seq)
	}
}

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("no .env file found, reading system env")
	}

	db, err := database.Connect()
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	db.SetMaxOpenConns(12)
	db.SetMaxIdleConns(6)
	db.SetConnMaxLifetime(5 * time.Minute)
	db.SetConnMaxIdleTime(60 * time.Second)

	ensureSchemaAndSkills(db)
	log.Println("successfully connected to Neon PostgreSQL & synced ATS + Events + Courses + Admin schema")

	skillRepo := repository.NewSkillRepository(db)
	vacancyRepo := repository.NewVacancyRepository(db)

	matchService := service.NewMatchService(skillRepo, vacancyRepo)
	matchHandler := handler.NewMatchHandler(matchService)

	router := gin.Default()

	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	api := router.Group("/api/v1")
	{
		api.GET("/health", func(c *gin.Context) {
			c.JSON(200, gin.H{"status": "ok", "database": "neon-postgres"})
		})

		api.POST("/auth/login", func(c *gin.Context) {
			var req AuthRequest
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(400, gin.H{"error": "Invalid request format"})
				return
			}

			var userID int64
			var passwordHash, role string
			var isAdmin bool
			err := db.QueryRow(`
				SELECT id, password_hash, role, COALESCE(is_admin, FALSE)
				FROM users
				WHERE LOWER(email) = LOWER($1)
			`, strings.TrimSpace(req.Email)).Scan(&userID, &passwordHash, &role, &isAdmin)

			if err == sql.ErrNoRows {
				c.JSON(404, gin.H{
					"error": "Account with this email does not exist. Please register first (Sign up).",
					"code":  "USER_NOT_FOUND",
				})
				return
			}
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			if passwordHash != req.Password {
				c.JSON(401, gin.H{
					"error": "Incorrect password. Please check your password and try again.",
					"code":  "INVALID_PASSWORD",
				})
				return
			}

			var profileID int64
			var displayName string
			switch role {
			case "STUDENT":
				_ = db.QueryRow(`SELECT id, full_name FROM student_profiles WHERE user_id = $1`, userID).Scan(&profileID, &displayName)
				if strings.Contains(strings.ToLower(displayName), "zhumabek") {
					isAdmin = true
				}
			case "COMPANY":
				_ = db.QueryRow(`SELECT id, name FROM companies WHERE user_id = $1`, userID).Scan(&profileID, &displayName)
			default:
				profileID = userID
				displayName = "Platform Administrator"
				isAdmin = true
			}

			c.JSON(200, gin.H{
				"user_id":    userID,
				"profile_id": profileID,
				"email":      strings.TrimSpace(req.Email),
				"role":       role,
				"name":       displayName,
				"is_admin":   isAdmin,
			})
		})

		api.POST("/auth/register", func(c *gin.Context) {
			var req AuthRequest
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(400, gin.H{"error": "Invalid request"})
				return
			}
			email := strings.TrimSpace(req.Email)
			name := strings.TrimSpace(req.Name)
			role := strings.ToUpper(strings.TrimSpace(req.Role))
			if role != "COMPANY" {
				role = "STUDENT"
			}
			if email == "" || req.Password == "" || name == "" {
				c.JSON(400, gin.H{"error": "Email, password and name are required"})
				return
			}

			tx, err := db.Begin()
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			defer func() { _ = tx.Rollback() }()

			isAdmin := strings.Contains(strings.ToLower(name), "zhumabek")
			var userID int64
			err = tx.QueryRow(`
				INSERT INTO users (email, password_hash, role, is_admin)
				VALUES ($1, $2, $3, $4)
				RETURNING id
			`, email, req.Password, role, isAdmin).Scan(&userID)
			if err != nil {
				c.JSON(409, gin.H{"error": "An account with this email already exists. Please sign in."})
				return
			}

			var profileID int64
			if role == "COMPANY" {
				desc := strings.TrimSpace(req.Description)
				err = tx.QueryRow(`
					INSERT INTO companies (user_id, name, industry, city, description)
					VALUES ($1, $2, 'IT & Digital', 'Almaty', $3)
					RETURNING id
				`, userID, name, desc).Scan(&profileID)
			} else {
				uni := strings.TrimSpace(req.University)
				if uni == "" {
					uni = "KBTU"
				}
				major := strings.TrimSpace(req.Major)
				if major == "" {
					major = "Information Systems"
				}
				err = tx.QueryRow(`
					INSERT INTO student_profiles (user_id, full_name, university, major, experience_years, bio, target_role)
					VALUES ($1, $2, $3, $4, $5, '', 'Software Engineering Intern')
					RETURNING id
				`, userID, name, uni, major, int(math.Round(req.ExperienceYears))).Scan(&profileID)
			}
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}

			if err := tx.Commit(); err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}

			c.JSON(201, gin.H{
				"user_id":    userID,
				"profile_id": profileID,
				"email":      email,
				"role":       role,
				"name":       name,
				"is_admin":   isAdmin,
			})
		})

		api.GET("/skills", func(c *gin.Context) {
			q := strings.TrimSpace(c.Query("q"))
			var rows *sql.Rows
			var err error

			if q != "" {
				rows, err = db.Query(`
					SELECT id, name, COALESCE(category, 'Technical')
					FROM skills
					WHERE LOWER(name) LIKE LOWER($1) OR LOWER(category) LIKE LOWER($1)
					ORDER BY name
				`, "%"+q+"%")
			} else {
				rows, err = db.Query(`
					SELECT id, name, COALESCE(category, 'Technical')
					FROM skills
					ORDER BY name
				`)
			}
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			defer rows.Close()

			items := make([]SkillCatalogItem, 0)
			for rows.Next() {
				var item SkillCatalogItem
				if err := rows.Scan(&item.ID, &item.Name, &item.Category); err == nil {
					items = append(items, item)
				}
			}
			if err := rows.Err(); err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(200, items)
		})

		students := api.Group("/students")
		{
			students.GET("/:id", func(c *gin.Context) {
				studentID := c.Param("id")
				var p StudentProfilePayload
				var err error

				for attempt := 0; attempt < 3; attempt++ {
					err = db.QueryRow(`
						SELECT
							sp.id,
							sp.user_id,
							sp.full_name,
							COALESCE(sp.university, 'KBTU'),
							COALESCE(sp.major, 'Information Systems'),
							COALESCE(sp.experience_years, 0)::FLOAT8,
							COALESCE(sp.bio, ''),
							COALESCE(sp.target_role, 'Software Engineering Intern'),
							COALESCE(sp.github_url, ''),
							COALESCE(sp.linkedin_url, ''),
							COALESCE(u.is_admin, FALSE)
						FROM student_profiles sp
						LEFT JOIN users u ON u.id = sp.user_id
						WHERE sp.id = $1
					`, studentID).Scan(
						&p.ID, &p.UserID, &p.FullName, &p.University,
						&p.Major, &p.ExperienceYears, &p.Bio,
						&p.TargetRole, &p.GithubURL, &p.LinkedinURL, &p.IsAdmin,
					)
					if err == nil || err == sql.ErrNoRows {
						break
					}
					time.Sleep(150 * time.Millisecond)
				}

				if err == sql.ErrNoRows {
					c.JSON(404, gin.H{"error": "student profile not found"})
					return
				}
				if err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				if strings.Contains(strings.ToLower(p.FullName), "zhumabek") {
					p.IsAdmin = true
				}
				c.JSON(200, p)
			})

			students.PUT("/:id", func(c *gin.Context) {
				studentID := c.Param("id")
				var req StudentProfilePayload
				if err := c.ShouldBindJSON(&req); err != nil {
					c.JSON(400, gin.H{"error": err.Error()})
					return
				}

				_, err := db.Exec(`
					UPDATE student_profiles
					SET full_name = $1,
					    university = $2,
					    major = $3,
					    experience_years = $4,
					    bio = $5,
					    target_role = $6,
					    github_url = $7,
					    linkedin_url = $8
					WHERE id = $9
				`,
					strings.TrimSpace(req.FullName),
					strings.TrimSpace(req.University),
					strings.TrimSpace(req.Major),
					int(math.Round(req.ExperienceYears)),
					strings.TrimSpace(req.Bio),
					strings.TrimSpace(req.TargetRole),
					strings.TrimSpace(req.GithubURL),
					strings.TrimSpace(req.LinkedinURL),
					studentID,
				)
				if err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				c.JSON(200, gin.H{"status": "updated"})
			})

			students.GET("/:id/skills", func(c *gin.Context) {
				studentID := c.Param("id")
				rows, err := db.Query(`
					SELECT s.id, s.name, COALESCE(s.category, 'Technical'), COALESCE(ss.proficiency_level, 'Intermediate')
					FROM student_skills ss
					JOIN skills s ON s.id = ss.skill_id
					WHERE ss.student_profile_id = $1
					ORDER BY s.name
				`, studentID)
				if err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				defer rows.Close()

				skills := make([]StudentSkillItem, 0)
				for rows.Next() {
					var item StudentSkillItem
					if err := rows.Scan(&item.ID, &item.Name, &item.Category, &item.Level); err == nil {
						skills = append(skills, item)
					}
				}
				if err := rows.Err(); err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				c.JSON(200, skills)
			})

			students.POST("/:id/skills", func(c *gin.Context) {
				studentID := c.Param("id")
				var req SkillRequest
				if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.Name) == "" {
					c.JSON(400, gin.H{"error": "skill name is required"})
					return
				}

				level := strings.TrimSpace(req.Level)
				if level != "Beginner" && level != "Intermediate" && level != "Advanced" {
					level = "Intermediate"
				}

				skillName := strings.TrimSpace(req.Name)
				var skillID int64
				err := db.QueryRow(`SELECT id FROM skills WHERE LOWER(name) = LOWER($1)`, skillName).Scan(&skillID)
				if err != nil {
					err = db.QueryRow(`
						INSERT INTO skills (name, category)
						VALUES ($1, 'Custom')
						RETURNING id
					`, skillName).Scan(&skillID)
					if err != nil {
						c.JSON(500, gin.H{"error": err.Error()})
						return
					}
				}

				_, err = db.Exec(`
					INSERT INTO student_skills (student_profile_id, skill_id, proficiency_level)
					VALUES ($1, $2, $3)
					ON CONFLICT (student_profile_id, skill_id)
					DO UPDATE SET proficiency_level = EXCLUDED.proficiency_level
				`, studentID, skillID, level)
				if err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}

				c.JSON(200, gin.H{"status": "success", "skill_id": skillID, "level": level})
			})

			students.DELETE("/:id/skills", func(c *gin.Context) {
				studentID := c.Param("id")
				skillName := c.Query("name")
				if skillName == "" {
					c.JSON(400, gin.H{"error": "skill name is required"})
					return
				}

				_, err := db.Exec(`
					DELETE FROM student_skills
					WHERE student_profile_id = $1
					AND skill_id = (SELECT id FROM skills WHERE LOWER(name) = LOWER($2) LIMIT 1)
				`, studentID, skillName)
				if err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}

				c.JSON(200, gin.H{"status": "deleted"})
			})

			students.GET("/:id/languages", func(c *gin.Context) {
				studentID := c.Param("id")
				rows, err := db.Query(`
					SELECT id, student_profile_id, language_name, cefr_level
					FROM student_languages
					WHERE student_profile_id = $1
					ORDER BY id
				`, studentID)
				if err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				defer rows.Close()

				langs := make([]LanguageItem, 0)
				for rows.Next() {
					var item LanguageItem
					if err := rows.Scan(&item.ID, &item.StudentProfileID, &item.LanguageName, &item.CefrLevel); err == nil {
						item.ProficiencyLevel = item.CefrLevel
						langs = append(langs, item)
					}
				}
				if err := rows.Err(); err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				c.JSON(200, langs)
			})

			students.POST("/:id/languages", func(c *gin.Context) {
				studentID := c.Param("id")
				var req AddLanguageRequest
				if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.LanguageName) == "" {
					c.JSON(400, gin.H{"error": "language_name is required"})
					return
				}
				cefr := strings.TrimSpace(req.CefrLevel)
				if cefr == "" {
					cefr = strings.TrimSpace(req.ProficiencyLevel)
				}
				cefr = strings.Fields(cefr)[0]
				if cefr != "A1" && cefr != "A2" && cefr != "B1" && cefr != "B2" && cefr != "C1" && cefr != "C2" {
					cefr = "B2"
				}

				_, err := db.Exec(`
					INSERT INTO student_languages (student_profile_id, language_name, cefr_level, verification_status)
					VALUES ($1, $2, $3, 'approved')
					ON CONFLICT (student_profile_id, language_name)
					DO UPDATE SET cefr_level = EXCLUDED.cefr_level
				`, studentID, strings.TrimSpace(req.LanguageName), cefr)
				if err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				c.JSON(200, gin.H{"status": "saved", "cefr_level": cefr})
			})

			students.DELETE("/:id/languages", func(c *gin.Context) {
				studentID := c.Param("id")
				langName := strings.TrimSpace(c.Query("language"))
				if langName == "" {
					langName = strings.TrimSpace(c.Query("name"))
				}
				if langName == "" {
					c.JSON(400, gin.H{"error": "language query parameter is required"})
					return
				}
				_, err := db.Exec(`
					DELETE FROM student_languages
					WHERE student_profile_id = $1
					AND LOWER(language_name) = LOWER($2)
				`, studentID, langName)
				if err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				c.JSON(200, gin.H{"status": "deleted"})
			})

			students.GET("/:id/applications", func(c *gin.Context) {
				studentID := c.Param("id")
				rows, err := db.Query(`
					SELECT
						a.id,
						a.vacancy_id,
						v.title,
						c.name,
						a.match_score,
						a.status,
						COALESCE(a.cover_letter, ''),
						COALESCE(a.company_feedback, ''),
						TO_CHAR(a.applied_at, 'YYYY-MM-DD HH24:MI'),
						TO_CHAR(COALESCE(a.updated_at, a.applied_at), 'YYYY-MM-DD HH24:MI')
					FROM applications a
					JOIN vacancies v ON v.id = a.vacancy_id
					JOIN companies c ON c.id = v.company_id
					WHERE a.student_profile_id = $1
					ORDER BY COALESCE(a.updated_at, a.applied_at) DESC
				`, studentID)
				if err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				defer rows.Close()

				apps := make([]gin.H, 0)
				for rows.Next() {
					var id, vacID int64
					var title, company, status, cover, feedback, appliedAt, updatedAt string
					var score int
					if err := rows.Scan(&id, &vacID, &title, &company, &score, &status, &cover, &feedback, &appliedAt, &updatedAt); err == nil {
						apps = append(apps, gin.H{
							"id":               id,
							"vacancy_id":       vacID,
							"title":            title,
							"company":          company,
							"match_score":      score,
							"status":           status,
							"cover_letter":     cover,
							"company_feedback": feedback,
							"applied_at":       appliedAt,
							"updated_at":       updatedAt,
						})
					}
				}
				if err := rows.Err(); err != nil {
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				c.JSON(200, apps)
			})
		}

		// =====================================
		// EVENTS (COMPANY + COMMUNITY MEETUPS)
		// =====================================
		api.GET("/events", func(c *gin.Context) {
			studentIDStr := strings.TrimSpace(c.Query("student_id"))
			companyIDStr := strings.TrimSpace(c.Query("company_id"))
			registeredSet := make(map[int64]bool)
			studentSkillsSet := make(map[string]bool)

			if studentIDStr != "" {
				rRows, err := db.Query(`SELECT event_id FROM event_registrations WHERE student_profile_id = $1`, studentIDStr)
				if err == nil {
					for rRows.Next() {
						var evID int64
						if err := rRows.Scan(&evID); err == nil {
							registeredSet[evID] = true
						}
					}
					if err := rRows.Err(); err != nil {
						log.Println("event_registrations rows err:", err)
					}
					rRows.Close()
				}

				sRows, err := db.Query(`
					SELECT LOWER(s.name)
					FROM student_skills ss
					JOIN skills s ON s.id = ss.skill_id
					WHERE ss.student_profile_id = $1
				`, studentIDStr)
				if err == nil {
					for sRows.Next() {
						var sName string
						if err := sRows.Scan(&sName); err == nil {
							studentSkillsSet[strings.TrimSpace(sName)] = true
						}
					}
					if err := sRows.Err(); err != nil {
						log.Println("student_skills rows err:", err)
					}
					sRows.Close()
				}
			}

			query := `
				SELECT
					e.id,
					COALESCE(e.company_id, 0),
					e.title,
					e.organizer,
					e.event_type,
					e.event_date,
					e.location,
					e.work_format,
					COALESCE(e.capacity, 100),
					COALESCE(e.external_url, ''),
					e.description,
					e.tags,
					(SELECT COUNT(*) FROM event_registrations er WHERE er.event_id = e.id)
				FROM events e
				WHERE 1=1
			`
			args := make([]interface{}, 0)
			if companyIDStr != "" {
				args = append(args, companyIDStr)
				query += ` AND e.company_id = $` + strconv.Itoa(len(args))
			}
			query += ` ORDER BY e.id DESC`

			rows, err := db.Query(query, args...)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			defer rows.Close()

			events := make([]EventItem, 0)
			for rows.Next() {
				var ev EventItem
				if err := rows.Scan(
					&ev.ID, &ev.CompanyID, &ev.Title, &ev.Organizer, &ev.EventType,
					&ev.EventDate, &ev.Location, &ev.WorkFormat,
					&ev.Capacity, &ev.ExternalURL,
					&ev.Description, &ev.Tags, &ev.RegisteredCount,
				); err == nil {
					ev.IsRegistered = registeredSet[ev.ID]
					ev.MatchedTags = make([]string, 0)
					for _, rawTag := range strings.Split(ev.Tags, ",") {
						tag := strings.TrimSpace(rawTag)
						if tag != "" && studentSkillsSet[strings.ToLower(tag)] {
							ev.MatchedTags = append(ev.MatchedTags, tag)
						}
					}
					ev.IsRecommended = len(ev.MatchedTags) > 0
					events = append(events, ev)
				}
			}
			if err := rows.Err(); err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(200, events)
		})

		api.POST("/events", func(c *gin.Context) {
			var req struct {
				CompanyID   int64  `json:"company_id"`
				Title       string `json:"title"`
				Organizer   string `json:"organizer"`
				EventType   string `json:"event_type"`
				EventDate   string `json:"event_date"`
				Location    string `json:"location"`
				WorkFormat  string `json:"work_format"`
				Capacity    int    `json:"capacity"`
				ExternalURL string `json:"external_url"`
				Description string `json:"description"`
				Tags        string `json:"tags"`
			}
			if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.Title) == "" {
				c.JSON(400, gin.H{"error": "title is required"})
				return
			}
			if req.Capacity <= 0 {
				req.Capacity = 100
			}
			if req.WorkFormat == "" {
				req.WorkFormat = "Offline"
			}
			if req.EventType == "" {
				req.EventType = "Tech Meetup"
			}
			if req.Location == "" {
				req.Location = "Almaty"
			}
			org := strings.TrimSpace(req.Organizer)
			if org == "" && req.CompanyID > 0 {
				_ = db.QueryRow(`SELECT name FROM companies WHERE id = $1`, req.CompanyID).Scan(&org)
			}
			if org == "" {
				org = "SkillMatch Partner"
			}

			var id int64
			err := db.QueryRow(`
				INSERT INTO events (company_id, title, organizer, event_type, event_date, location, work_format, capacity, external_url, description, tags)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
				RETURNING id
			`,
				req.CompanyID,
				strings.TrimSpace(req.Title),
				org,
				req.EventType,
				strings.TrimSpace(req.EventDate),
				strings.TrimSpace(req.Location),
				req.WorkFormat,
				req.Capacity,
				strings.TrimSpace(req.ExternalURL),
				strings.TrimSpace(req.Description),
				strings.TrimSpace(req.Tags),
			).Scan(&id)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(201, gin.H{"id": id, "status": "created"})
		})

		api.DELETE("/events/:id", func(c *gin.Context) {
			eventID := c.Param("id")
			_, _ = db.Exec(`DELETE FROM event_registrations WHERE event_id = $1`, eventID)
			_, err := db.Exec(`DELETE FROM events WHERE id = $1`, eventID)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(200, gin.H{"status": "deleted"})
		})

		api.POST("/events/:id/toggle", func(c *gin.Context) {
			eventID, _ := strconv.ParseInt(c.Param("id"), 10, 64)
			var body struct {
				StudentProfileID int64 `json:"student_profile_id"`
			}
			if err := c.ShouldBindJSON(&body); err != nil || body.StudentProfileID <= 0 {
				c.JSON(400, gin.H{"error": "student_profile_id is required"})
				return
			}

			var existingID int64
			err := db.QueryRow(`
				SELECT id FROM event_registrations
				WHERE event_id = $1 AND student_profile_id = $2
			`, eventID, body.StudentProfileID).Scan(&existingID)

			if err == nil {
				_, _ = db.Exec(`DELETE FROM event_registrations WHERE id = $1`, existingID)
				var cnt int
				_ = db.QueryRow(`SELECT COUNT(*) FROM event_registrations WHERE event_id = $1`, eventID).Scan(&cnt)
				c.JSON(200, gin.H{"registered": false, "registered_count": cnt})
				return
			}

			var capacity, currentCount int
			_ = db.QueryRow(`
				SELECT COALESCE(capacity, 100),
				       (SELECT COUNT(*) FROM event_registrations WHERE event_id = $1)
				FROM events WHERE id = $1
			`, eventID).Scan(&capacity, &currentCount)

			if capacity > 0 && currentCount >= capacity {
				c.JSON(400, gin.H{"error": "All spots for this event are full"})
				return
			}

			_, err = db.Exec(`
				INSERT INTO event_registrations (event_id, student_profile_id)
				VALUES ($1, $2)
				ON CONFLICT DO NOTHING
			`, eventID, body.StudentProfileID)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			var cnt int
			_ = db.QueryRow(`SELECT COUNT(*) FROM event_registrations WHERE event_id = $1`, eventID).Scan(&cnt)
			c.JSON(200, gin.H{"registered": true, "registered_count": cnt})
		})

		// =====================================
		// COURSES (COMPANY COURSES + LIVE STEPIK CACHE + FILTERS)
		// =====================================
		api.GET("/courses", func(c *gin.Context) {
			studentIDStr := strings.TrimSpace(c.Query("student_id"))
			companyIDStr := strings.TrimSpace(c.Query("company_id"))
			skillFilter := strings.TrimSpace(c.Query("skill"))
			freeOnly := c.Query("free_only") == "true"
			langFilter := strings.ToUpper(strings.TrimSpace(c.Query("lang")))
			levelFilter := strings.TrimSpace(c.Query("level"))
			providerFilter := strings.TrimSpace(c.Query("provider"))
			searchQ := strings.ToLower(strings.TrimSpace(c.Query("q")))

			// Если запрошен конкретный навык и по нему ещё нет курсов в БД — подтягиваем со Stepik API и кэшируем в Neon
			if skillFilter != "" {
				var existingCount int
				_ = db.QueryRow(`SELECT COUNT(*) FROM courses WHERE LOWER(skill_name) = LOWER($1)`, skillFilter).Scan(&existingCount)
				if existingCount == 0 {
					fetchAndCacheLiveCourses(db, skillFilter)
				}
			}

			ownedSkillLevel := make(map[string]string)
			enrollments := make(map[int64]string)
			vacancyDemandCount := make(map[string]int)

			if studentIDStr != "" {
				sRows, err := db.Query(`
					SELECT LOWER(s.name), COALESCE(ss.proficiency_level, 'Intermediate')
					FROM student_skills ss
					JOIN skills s ON s.id = ss.skill_id
					WHERE ss.student_profile_id = $1
				`, studentIDStr)
				if err == nil {
					for sRows.Next() {
						var sName, lvl string
						if err := sRows.Scan(&sName, &lvl); err == nil {
							ownedSkillLevel[strings.TrimSpace(sName)] = lvl
						}
					}
					if err := sRows.Err(); err != nil {
						log.Println("courses student_skills rows err:", err)
					}
					sRows.Close()
				}

				cRows, err := db.Query(`
					SELECT course_id, status
					FROM student_courses
					WHERE student_profile_id = $1
				`, studentIDStr)
				if err == nil {
					for cRows.Next() {
						var cID int64
						var st string
						if err := cRows.Scan(&cID, &st); err == nil {
							enrollments[cID] = st
						}
					}
					if err := cRows.Err(); err != nil {
						log.Println("student_courses rows err:", err)
					}
					cRows.Close()
				}

				vRows, err := db.Query(`
					SELECT LOWER(s.name), COUNT(DISTINCT vs.vacancy_id)
					FROM vacancy_skills vs
					JOIN vacancies v ON v.id = vs.vacancy_id
					JOIN skills s ON s.id = vs.skill_id
					WHERE COALESCE(v.is_active, TRUE) = TRUE
					GROUP BY LOWER(s.name)
				`)
				if err == nil {
					for vRows.Next() {
						var sName string
						var cnt int
						if err := vRows.Scan(&sName, &cnt); err == nil {
							vacancyDemandCount[strings.TrimSpace(sName)] = cnt
						}
					}
					if err := vRows.Err(); err != nil {
						log.Println("vacancy_skills rows err:", err)
					}
					vRows.Close()
				}
			}

			query := `
				SELECT id, COALESCE(company_id, 0), title, provider, skill_name, level, COALESCE(language, 'RU'), duration, is_free, COALESCE(external_url, ''), description
				FROM courses
				WHERE 1=1
			`
			args := make([]interface{}, 0)
			if companyIDStr != "" {
				args = append(args, companyIDStr)
				query += ` AND company_id = $` + strconv.Itoa(len(args))
			}
			// Приоритет курсам, созданным компаниями (company_id > 0)
			query += ` ORDER BY (CASE WHEN COALESCE(company_id, 0) > 0 THEN 0 ELSE 1 END) ASC, id DESC`

			rows, err := db.Query(query, args...)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			defer rows.Close()

			courses := make([]CourseItem, 0)
			for rows.Next() {
				var item CourseItem
				if err := rows.Scan(
					&item.ID, &item.CompanyID, &item.Title, &item.Provider, &item.SkillName,
					&item.Level, &item.Language, &item.Duration, &item.IsFree, &item.ExternalURL, &item.Description,
				); err == nil {
					if freeOnly && !item.IsFree {
						continue
					}
					if skillFilter != "" && !strings.EqualFold(item.SkillName, skillFilter) {
						continue
					}
					if langFilter != "" && langFilter != "ALL" && !strings.EqualFold(item.Language, langFilter) {
						continue
					}
					if levelFilter != "" && !strings.EqualFold(levelFilter, "All") && !strings.EqualFold(item.Level, levelFilter) {
						continue
					}
					if providerFilter != "" && !strings.EqualFold(providerFilter, "All") {
						if strings.EqualFold(providerFilter, "Company") {
							if item.CompanyID <= 0 {
								continue
							}
						} else if !strings.Contains(strings.ToLower(item.Provider), strings.ToLower(providerFilter)) {
							continue
						}
					}
					if searchQ != "" &&
						!strings.Contains(strings.ToLower(item.Title), searchQ) &&
						!strings.Contains(strings.ToLower(item.SkillName), searchQ) &&
						!strings.Contains(strings.ToLower(item.Provider), searchQ) {
						continue
					}

					item.EnrollmentStatus = enrollments[item.ID]
					key := strings.ToLower(strings.TrimSpace(item.SkillName))
					demand := vacancyDemandCount[key]
					item.BoostedVacanciesCount = demand

					currentLvl, hasSkill := ownedSkillLevel[key]
					if !hasSkill {
						item.IsRecommended = true
						if item.CompanyID > 0 {
							item.RecommendationReason = "Partner Course (" + item.Provider + ") • Closes skill gap"
						} else if demand > 0 {
							item.RecommendationReason = "Closes skill gap for " + strconv.Itoa(demand) + " open vacancies"
						} else {
							item.RecommendationReason = "Adds new skill (" + item.SkillName + ") to your profile"
						}
					} else if skillWeight(item.Level) > skillWeight(currentLvl) {
						item.IsRecommended = true
						item.RecommendationReason = "Upgrades " + item.SkillName + ": " + currentLvl + " → " + item.Level
					}
					courses = append(courses, item)
				}
			}
			if err := rows.Err(); err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(200, courses)
		})

		api.POST("/courses", func(c *gin.Context) {
			var req struct {
				CompanyID   int64  `json:"company_id"`
				Title       string `json:"title"`
				Provider    string `json:"provider"`
				SkillName   string `json:"skill_name"`
				Level       string `json:"level"`
				Language    string `json:"language"`
				Duration    string `json:"duration"`
				IsFree      bool   `json:"is_free"`
				ExternalURL string `json:"external_url"`
				Description string `json:"description"`
			}
			if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.Title) == "" || strings.TrimSpace(req.SkillName) == "" {
				c.JSON(400, gin.H{"error": "title and skill_name are required"})
				return
			}
			provider := strings.TrimSpace(req.Provider)
			if provider == "" && req.CompanyID > 0 {
				_ = db.QueryRow(`SELECT name FROM companies WHERE id = $1`, req.CompanyID).Scan(&provider)
			}
			if provider == "" {
				provider = "Partner Academy"
			}
			level := strings.TrimSpace(req.Level)
			if level == "" {
				level = "Intermediate"
			}
			lang := strings.ToUpper(strings.TrimSpace(req.Language))
			if lang != "EN" {
				lang = "RU"
			}
			dur := strings.TrimSpace(req.Duration)
			if dur == "" {
				dur = "2 weeks"
			}

			var id int64
			err := db.QueryRow(`
				INSERT INTO courses (company_id, title, provider, skill_name, level, language, duration, is_free, external_url, description)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
				RETURNING id
			`,
				req.CompanyID,
				strings.TrimSpace(req.Title),
				provider,
				strings.TrimSpace(req.SkillName),
				level,
				lang,
				dur,
				req.IsFree,
				strings.TrimSpace(req.ExternalURL),
				strings.TrimSpace(req.Description),
			).Scan(&id)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(201, gin.H{"id": id, "status": "created"})
		})

		api.DELETE("/courses/:id", func(c *gin.Context) {
			courseID := c.Param("id")
			_, _ = db.Exec(`DELETE FROM student_courses WHERE course_id = $1`, courseID)
			_, err := db.Exec(`DELETE FROM courses WHERE id = $1`, courseID)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(200, gin.H{"status": "deleted"})
		})

		api.POST("/courses/:id/status", func(c *gin.Context) {
			courseID, _ := strconv.ParseInt(c.Param("id"), 10, 64)
			var body struct {
				StudentProfileID int64  `json:"student_profile_id"`
				Status           string `json:"status"`
			}
			if err := c.ShouldBindJSON(&body); err != nil || body.StudentProfileID <= 0 {
				c.JSON(400, gin.H{"error": "student_profile_id is required"})
				return
			}

			status := "Enrolled"
			if strings.EqualFold(strings.TrimSpace(body.Status), "completed") {
				status = "Completed"
			}

			_, err := db.Exec(`
				INSERT INTO student_courses (course_id, student_profile_id, status, updated_at)
				VALUES ($1, $2, $3, NOW())
				ON CONFLICT (course_id, student_profile_id)
				DO UPDATE SET status = EXCLUDED.status, updated_at = NOW()
			`, courseID, body.StudentProfileID, status)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}

			addedSkill := ""
			addedLevel := ""
			boostedVacancies := 0
			if status == "Completed" {
				var skillName, courseLevel string
				err := db.QueryRow(`SELECT skill_name, level FROM courses WHERE id = $1`, courseID).Scan(&skillName, &courseLevel)
				if err == nil && strings.TrimSpace(skillName) != "" {
					var skillID int64
					err = db.QueryRow(`SELECT id FROM skills WHERE LOWER(name) = LOWER($1)`, skillName).Scan(&skillID)
					if err != nil {
						_ = db.QueryRow(`INSERT INTO skills (name, category) VALUES ($1, 'Course') RETURNING id`, skillName).Scan(&skillID)
					}
					if skillID > 0 {
						_, _ = db.Exec(`
							INSERT INTO student_skills (student_profile_id, skill_id, proficiency_level)
							VALUES ($1, $2, $3)
							ON CONFLICT (student_profile_id, skill_id)
							DO UPDATE SET proficiency_level = CASE
								WHEN student_skills.proficiency_level = 'Beginner' AND EXCLUDED.proficiency_level IN ('Intermediate', 'Advanced') THEN EXCLUDED.proficiency_level
								WHEN student_skills.proficiency_level = 'Intermediate' AND EXCLUDED.proficiency_level = 'Advanced' THEN EXCLUDED.proficiency_level
								ELSE student_skills.proficiency_level
							END
						`, body.StudentProfileID, skillID, courseLevel)
						addedSkill = skillName
						addedLevel = courseLevel

						_ = db.QueryRow(`
							SELECT COUNT(DISTINCT vs.vacancy_id)
							FROM vacancy_skills vs
							JOIN vacancies v ON v.id = vs.vacancy_id
							WHERE vs.skill_id = $1 AND COALESCE(v.is_active, TRUE) = TRUE
						`, skillID).Scan(&boostedVacancies)
					}
				}
			}

			c.JSON(200, gin.H{
				"status":            status,
				"added_skill":       addedSkill,
				"added_level":       addedLevel,
				"boosted_vacancies": boostedVacancies,
			})
		})

		// =====================================
		// VACANCIES + APPLY / WITHDRAW
		// =====================================
		api.GET("/vacancies", func(c *gin.Context) {
			studentIDStr := c.Query("student_id")
			companyIDStr := c.Query("company_id")
			includeInactive := c.Query("include_inactive") == "true"

			type appMeta struct {
				id          int64
				status      string
				coverLetter string
				feedback    string
			}
			studentSkillLevels := make(map[string]string)
			studentApps := make(map[int64]appMeta)

			if studentIDStr != "" {
				sRows, err := db.Query(`
					SELECT LOWER(s.name), COALESCE(ss.proficiency_level, 'Intermediate')
					FROM student_skills ss
					JOIN skills s ON s.id = ss.skill_id
					WHERE ss.student_profile_id = $1
				`, studentIDStr)
				if err == nil {
					for sRows.Next() {
						var sName, sLvl string
						if err := sRows.Scan(&sName, &sLvl); err == nil {
							studentSkillLevels[sName] = sLvl
						}
					}
					if err := sRows.Err(); err != nil {
						log.Println("vacancies student_skills rows err:", err)
					}
					sRows.Close()
				}

				aRows, err := db.Query(`
					SELECT id, vacancy_id, status, COALESCE(cover_letter, ''), COALESCE(company_feedback, '')
					FROM applications
					WHERE student_profile_id = $1
				`, studentIDStr)
				if err == nil {
					for aRows.Next() {
						var appID, vID int64
						var st, cover, fb string
						if err := aRows.Scan(&appID, &vID, &st, &cover, &fb); err == nil {
							studentApps[vID] = appMeta{id: appID, status: st, coverLetter: cover, feedback: fb}
						}
					}
					if err := aRows.Err(); err != nil {
						log.Println("applications rows err:", err)
					}
					aRows.Close()
				}
			}

			query := `
				SELECT
					v.id,
					v.company_id,
					c.name,
					v.title,
					COALESCE(v.description, ''),
					COALESCE(v.experience_required, 0)::FLOAT8,
					COALESCE(v.employment_type, 'Internship'),
					COALESCE(v.work_format, 'Hybrid'),
					COALESCE(v.location, 'Almaty'),
					COALESCE(v.salary_range, ''),
					COALESCE(v.is_active, TRUE),
					(SELECT COUNT(*) FROM applications a WHERE a.vacancy_id = v.id AND a.status <> 'Withdrawn'),
					(SELECT COUNT(*) FROM applications a WHERE a.vacancy_id = v.id AND a.status = 'Applied')
				FROM vacancies v
				JOIN companies c ON c.id = v.company_id
				WHERE 1=1
			`
			args := make([]interface{}, 0)
			if companyIDStr != "" {
				args = append(args, companyIDStr)
				query += ` AND v.company_id = $` + strconv.Itoa(len(args))
			} else if !includeInactive {
				query += ` AND COALESCE(v.is_active, TRUE) = TRUE`
			}
			query += ` ORDER BY v.id DESC`

			rows, err := db.Query(query, args...)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}

			vacancies := make([]VacancyResponse, 0)
			for rows.Next() {
				var v VacancyResponse
				if err := rows.Scan(
					&v.ID, &v.CompanyID, &v.CompanyName, &v.Title,
					&v.Description, &v.ExperienceRequired, &v.EmploymentType,
					&v.WorkFormat, &v.Location, &v.SalaryRange,
					&v.IsActive, &v.ApplicantsCount, &v.NewApplicantsCount,
				); err == nil {
					if appInfo, ok := studentApps[v.ID]; ok {
						v.ApplicationID = appInfo.id
						v.AppliedStatus = appInfo.status
						v.CoverLetter = appInfo.coverLetter
						v.CompanyFeedback = appInfo.feedback
					}
					vacancies = append(vacancies, v)
				}
			}
			if err := rows.Err(); err != nil {
				rows.Close()
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			rows.Close()

			for i := range vacancies {
				skillRows, err := db.Query(`
					SELECT s.name, COALESCE(vs.required_level, 'Intermediate')
					FROM vacancy_skills vs
					JOIN skills s ON s.id = vs.skill_id
					WHERE vs.vacancy_id = $1
					ORDER BY s.name
				`, vacancies[i].ID)

				vacancies[i].Skills = make([]string, 0)
				vacancies[i].MatchedSkills = make([]string, 0)
				vacancies[i].MissingSkills = make([]string, 0)

				var earned, total float64
				if err == nil {
					for skillRows.Next() {
						var sName, reqLvl string
						if err := skillRows.Scan(&sName, &reqLvl); err == nil {
							vacancies[i].Skills = append(vacancies[i].Skills, sName)
							total += 1.0

							if stLvl, ok := studentSkillLevels[strings.ToLower(strings.TrimSpace(sName))]; ok {
								vacancies[i].MatchedSkills = append(vacancies[i].MatchedSkills, sName)
								sRank := skillWeight(stLvl)
								rRank := skillWeight(reqLvl)
								if sRank >= rRank {
									earned += 1.0
								} else if rRank-sRank == 1 {
									earned += 0.75
								} else {
									earned += 0.50
								}
							} else {
								vacancies[i].MissingSkills = append(vacancies[i].MissingSkills, sName)
							}
						}
					}
					if err := skillRows.Err(); err != nil {
						log.Println("vacancy_skills skillRows err:", err)
					}
					skillRows.Close()
				}

				if total > 0 && len(studentSkillLevels) > 0 {
					vacancies[i].MatchScore = int(math.Round((earned / total) * 100))
				}
			}

			c.JSON(200, vacancies)
		})

		api.POST("/vacancies", func(c *gin.Context) {
			var req CreateVacancyRequest
			if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.Title) == "" {
				c.JSON(400, gin.H{"error": "title is required"})
				return
			}
			if req.CompanyID <= 0 {
				req.CompanyID = 1
			}
			if req.EmploymentType == "" {
				req.EmploymentType = "Internship"
			}
			if req.WorkFormat == "" {
				req.WorkFormat = "Hybrid"
			}
			if req.Location == "" {
				req.Location = "Almaty"
			}

			var vacancyID int64
			err := db.QueryRow(`
				INSERT INTO vacancies (company_id, title, description, employment_type, work_format, location, experience_required, salary_range, is_active)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8, TRUE)
				RETURNING id
			`, req.CompanyID, strings.TrimSpace(req.Title), req.Description, req.EmploymentType, req.WorkFormat, req.Location, req.ExperienceRequired, req.SalaryRange).Scan(&vacancyID)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}

			for _, rawSkill := range req.Skills {
				sName := strings.TrimSpace(rawSkill)
				if sName == "" {
					continue
				}
				var skillID int64
				err := db.QueryRow(`SELECT id FROM skills WHERE LOWER(name) = LOWER($1)`, sName).Scan(&skillID)
				if err != nil {
					_ = db.QueryRow(`INSERT INTO skills (name, category) VALUES ($1, 'Technical') RETURNING id`, sName).Scan(&skillID)
				}
				if skillID > 0 {
					_, _ = db.Exec(`
						INSERT INTO vacancy_skills (vacancy_id, skill_id, required_level)
						VALUES ($1, $2, 'Intermediate')
						ON CONFLICT DO NOTHING
					`, vacancyID, skillID)
				}
			}

			c.JSON(201, gin.H{"id": vacancyID, "status": "created"})
		})

		api.PATCH("/vacancies/:id/status", func(c *gin.Context) {
			vacancyID := c.Param("id")
			var body struct {
				IsActive bool `json:"is_active"`
			}
			if err := c.ShouldBindJSON(&body); err != nil {
				c.JSON(400, gin.H{"error": "invalid payload"})
				return
			}
			_, err := db.Exec(`UPDATE vacancies SET is_active = $1 WHERE id = $2`, body.IsActive, vacancyID)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(200, gin.H{"status": "updated", "is_active": body.IsActive})
		})

		api.DELETE("/vacancies/:id", func(c *gin.Context) {
			vacancyID := c.Param("id")
			_, _ = db.Exec(`DELETE FROM applications WHERE vacancy_id = $1`, vacancyID)
			_, _ = db.Exec(`DELETE FROM vacancy_skills WHERE vacancy_id = $1`, vacancyID)
			_, err := db.Exec(`DELETE FROM vacancies WHERE id = $1`, vacancyID)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(200, gin.H{"status": "deleted"})
		})

		api.POST("/vacancies/:id/apply", func(c *gin.Context) {
			vacancyID, _ := strconv.ParseInt(c.Param("id"), 10, 64)
			var body struct {
				StudentProfileID int64  `json:"student_profile_id"`
				MatchScore       int    `json:"match_score"`
				CoverLetter      string `json:"cover_letter"`
			}
			if err := c.ShouldBindJSON(&body); err != nil || body.StudentProfileID <= 0 {
				c.JSON(400, gin.H{"error": "student_profile_id is required"})
				return
			}

			var isActive bool
			err := db.QueryRow(`SELECT COALESCE(is_active, TRUE) FROM vacancies WHERE id = $1`, vacancyID).Scan(&isActive)
			if err == sql.ErrNoRows {
				c.JSON(404, gin.H{"error": "Vacancy not found"})
				return
			}
			if !isActive {
				c.JSON(400, gin.H{"error": "This vacancy is paused and no longer accepting applications"})
				return
			}

			var existingStatus string
			err = db.QueryRow(`
				SELECT status FROM applications
				WHERE vacancy_id = $1 AND student_profile_id = $2
			`, vacancyID, body.StudentProfileID).Scan(&existingStatus)

			if err == nil && existingStatus != "Withdrawn" {
				c.JSON(200, gin.H{
					"status":         existingStatus,
					"alreadyApplied": true,
					"message":        "You have already applied to this vacancy",
				})
				return
			}

			_, err = db.Exec(`
				INSERT INTO applications (vacancy_id, student_profile_id, match_score, status, cover_letter, company_feedback, updated_at)
				VALUES ($1, $2, $3, 'Applied', $4, '', NOW())
				ON CONFLICT (vacancy_id, student_profile_id)
				DO UPDATE SET
					match_score = EXCLUDED.match_score,
					status = 'Applied',
					cover_letter = EXCLUDED.cover_letter,
					company_feedback = '',
					updated_at = NOW()
			`, vacancyID, body.StudentProfileID, body.MatchScore, strings.TrimSpace(body.CoverLetter))
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(200, gin.H{"status": "Applied"})
		})

		api.PATCH("/applications/:id/withdraw", func(c *gin.Context) {
			appID := c.Param("id")
			_, err := db.Exec(`
				UPDATE applications
				SET status = 'Withdrawn', updated_at = NOW()
				WHERE id = $1 AND status = 'Applied'
			`, appID)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			c.JSON(200, gin.H{"status": "Withdrawn"})
		})

		api.GET("/companies/:id/applicants", func(c *gin.Context) {
			companyID := c.Param("id")
			vacancyFilter := strings.TrimSpace(c.Query("vacancy_id"))
			statusFilter := strings.TrimSpace(c.Query("status"))

			query := `
				SELECT
					a.id,
					a.vacancy_id,
					v.title,
					sp.id,
					sp.full_name,
					COALESCE(u.email, ''),
					COALESCE(sp.university, 'KBTU'),
					COALESCE(sp.major, 'Information Systems'),
					COALESCE(sp.experience_years, 0)::FLOAT8,
					COALESCE(sp.target_role, 'Student'),
					COALESCE(sp.bio, ''),
					COALESCE(sp.github_url, ''),
					COALESCE(sp.linkedin_url, ''),
					a.match_score,
					a.status,
					COALESCE(a.cover_letter, ''),
					COALESCE(a.company_feedback, ''),
					TO_CHAR(a.applied_at, 'YYYY-MM-DD HH24:MI'),
					TO_CHAR(COALESCE(a.updated_at, a.applied_at), 'YYYY-MM-DD HH24:MI')
				FROM applications a
				JOIN vacancies v ON v.id = a.vacancy_id
				JOIN student_profiles sp ON sp.id = a.student_profile_id
				LEFT JOIN users u ON u.id = sp.user_id
				WHERE v.company_id = $1
				  AND a.status <> 'Withdrawn'
			`
			args := []interface{}{companyID}

			if vacancyFilter != "" && vacancyFilter != "0" {
				args = append(args, vacancyFilter)
				query += ` AND a.vacancy_id = $` + strconv.Itoa(len(args))
			}
			if statusFilter != "" && strings.ToLower(statusFilter) != "all" {
				args = append(args, statusFilter)
				query += ` AND LOWER(a.status) = LOWER($` + strconv.Itoa(len(args)) + `)`
			}

			query += ` ORDER BY a.match_score DESC, a.applied_at DESC`

			rows, err := db.Query(query, args...)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}

			applicants := make([]CompanyApplicantItem, 0)
			for rows.Next() {
				var item CompanyApplicantItem
				if err := rows.Scan(
					&item.ApplicationID,
					&item.VacancyID,
					&item.VacancyTitle,
					&item.StudentProfileID,
					&item.StudentName,
					&item.StudentEmail,
					&item.University,
					&item.Major,
					&item.ExperienceYears,
					&item.TargetRole,
					&item.Bio,
					&item.GithubURL,
					&item.LinkedinURL,
					&item.MatchScore,
					&item.Status,
					&item.CoverLetter,
					&item.CompanyFeedback,
					&item.AppliedAt,
					&item.UpdatedAt,
				); err == nil {
					applicants = append(applicants, item)
				}
			}
			if err := rows.Err(); err != nil {
				rows.Close()
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}
			rows.Close()

			for i := range applicants {
				stID := applicants[i].StudentProfileID
				vacID := applicants[i].VacancyID

				stSkillSet := make(map[string]bool)
				applicants[i].StudentSkills = make([]StudentSkillItem, 0)
				skRows, err := db.Query(`
					SELECT s.id, s.name, COALESCE(s.category, 'Technical'), COALESCE(ss.proficiency_level, 'Intermediate')
					FROM student_skills ss
					JOIN skills s ON s.id = ss.skill_id
					WHERE ss.student_profile_id = $1
					ORDER BY s.name
				`, stID)
				if err == nil {
					for skRows.Next() {
						var sk StudentSkillItem
						if err := skRows.Scan(&sk.ID, &sk.Name, &sk.Category, &sk.Level); err == nil {
							applicants[i].StudentSkills = append(applicants[i].StudentSkills, sk)
							stSkillSet[strings.ToLower(strings.TrimSpace(sk.Name))] = true
						}
					}
					if err := skRows.Err(); err != nil {
						log.Println("applicants skRows err:", err)
					}
					skRows.Close()
				}

				applicants[i].StudentLanguages = make([]LanguageItem, 0)
				lgRows, err := db.Query(`
					SELECT id, student_profile_id, language_name, cefr_level
					FROM student_languages
					WHERE student_profile_id = $1
					ORDER BY id
				`, stID)
				if err == nil {
					for lgRows.Next() {
						var lg LanguageItem
						if err := lgRows.Scan(&lg.ID, &lg.StudentProfileID, &lg.LanguageName, &lg.CefrLevel); err == nil {
							lg.ProficiencyLevel = lg.CefrLevel
							applicants[i].StudentLanguages = append(applicants[i].StudentLanguages, lg)
						}
					}
					if err := lgRows.Err(); err != nil {
						log.Println("applicants lgRows err:", err)
					}
					lgRows.Close()
				}

				applicants[i].MatchedSkills = make([]string, 0)
				applicants[i].MissingSkills = make([]string, 0)
				vsRows, err := db.Query(`
					SELECT s.name
					FROM vacancy_skills vs
					JOIN skills s ON s.id = vs.skill_id
					WHERE vs.vacancy_id = $1
					ORDER BY s.name
				`, vacID)
				if err == nil {
					for vsRows.Next() {
						var vSkill string
						if err := vsRows.Scan(&vSkill); err == nil {
							if stSkillSet[strings.ToLower(strings.TrimSpace(vSkill))] {
								applicants[i].MatchedSkills = append(applicants[i].MatchedSkills, vSkill)
							} else {
								applicants[i].MissingSkills = append(applicants[i].MissingSkills, vSkill)
							}
						}
					}
					if err := vsRows.Err(); err != nil {
						log.Println("applicants vsRows err:", err)
					}
					vsRows.Close()
				}

				applicants[i].RegisteredEvents = make([]string, 0)
				evRows, err := db.Query(`
					SELECT e.title
					FROM event_registrations er
					JOIN events e ON e.id = er.event_id
					WHERE er.student_profile_id = $1
					ORDER BY e.event_date ASC
				`, stID)
				if err == nil {
					for evRows.Next() {
						var evTitle string
						if err := evRows.Scan(&evTitle); err == nil {
							applicants[i].RegisteredEvents = append(applicants[i].RegisteredEvents, evTitle)
						}
					}
					if err := evRows.Err(); err != nil {
						log.Println("applicants evRows err:", err)
					}
					evRows.Close()
				}
			}

			c.JSON(200, applicants)
		})

		api.PATCH("/applications/:id/status", func(c *gin.Context) {
			appID := c.Param("id")
			var req struct {
				Status          string `json:"status"`
				CompanyFeedback string `json:"company_feedback"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(400, gin.H{"error": "invalid payload"})
				return
			}

			status := strings.TrimSpace(req.Status)
			switch strings.ToLower(status) {
			case "approved":
				status = "Approved"
			case "rejected":
				status = "Rejected"
			case "interview":
				status = "Interview"
			case "applied":
				status = "Applied"
			default:
				c.JSON(400, gin.H{"error": "status must be Applied, Interview, Approved, or Rejected"})
				return
			}

			_, err := db.Exec(`
				UPDATE applications
				SET status = $1,
				    company_feedback = $2,
				    updated_at = NOW()
				WHERE id = $3
			`, status, strings.TrimSpace(req.CompanyFeedback), appID)
			if err != nil {
				c.JSON(500, gin.H{"error": err.Error()})
				return
			}

			c.JSON(200, gin.H{
				"status":           status,
				"company_feedback": strings.TrimSpace(req.CompanyFeedback),
			})
		})

		// =====================================
		// ADMIN ANALYTICS & MODERATION
		// =====================================
		api.GET("/admin/analytics", func(c *gin.Context) {
			var totalStudents, totalCompanies, totalVacancies, activeVacancies int
			var totalApps, interviewsCount, approvedCount, totalEvents, totalCourses int

			_ = db.QueryRow(`SELECT COUNT(*) FROM student_profiles`).Scan(&totalStudents)
			_ = db.QueryRow(`SELECT COUNT(*) FROM companies`).Scan(&totalCompanies)
			_ = db.QueryRow(`SELECT COUNT(*) FROM vacancies`).Scan(&totalVacancies)
			_ = db.QueryRow(`SELECT COUNT(*) FROM vacancies WHERE COALESCE(is_active, TRUE) = TRUE`).Scan(&activeVacancies)
			_ = db.QueryRow(`SELECT COUNT(*) FROM applications WHERE status <> 'Withdrawn'`).Scan(&totalApps)
			_ = db.QueryRow(`SELECT COUNT(*) FROM applications WHERE status = 'Interview'`).Scan(&interviewsCount)
			_ = db.QueryRow(`SELECT COUNT(*) FROM applications WHERE status = 'Approved'`).Scan(&approvedCount)
			_ = db.QueryRow(`SELECT COUNT(*) FROM events`).Scan(&totalEvents)
			_ = db.QueryRow(`SELECT COUNT(*) FROM courses`).Scan(&totalCourses)

			// 1. Аналитика по университетам
			universities := make([]gin.H, 0)
			uRows, err := db.Query(`
				SELECT
					COALESCE(NULLIF(TRIM(sp.university), ''), 'Other') AS uni,
					COUNT(DISTINCT sp.id) AS students_cnt,
					COUNT(DISTINCT CASE WHEN a.status <> 'Withdrawn' THEN a.id END) AS apps_cnt,
					COUNT(DISTINCT CASE WHEN a.status = 'Approved' THEN a.id END) AS approved_cnt
				FROM student_profiles sp
				LEFT JOIN applications a ON a.student_profile_id = sp.id
				GROUP BY uni
				ORDER BY students_cnt DESC, apps_cnt DESC
			`)
			if err == nil {
				for uRows.Next() {
					var uni string
					var stCnt, appCnt, appvCnt int
					if err := uRows.Scan(&uni, &stCnt, &appCnt, &appvCnt); err == nil {
						universities = append(universities, gin.H{
							"university":         uni,
							"students_count":     stCnt,
							"applications_count": appCnt,
							"approved_count":     appvCnt,
						})
					}
				}
				if err := uRows.Err(); err != nil {
					log.Println("admin uRows err:", err)
				}
				uRows.Close()
			}

			// 2. Активность компаний
			companies := make([]gin.H, 0)
			cRows, err := db.Query(`
				SELECT
					c.id,
					c.name,
					COALESCE(c.industry, 'IT & Digital'),
					(SELECT COUNT(*) FROM vacancies v WHERE v.company_id = c.id),
					(SELECT COUNT(*) FROM vacancies v WHERE v.company_id = c.id AND COALESCE(v.is_active, TRUE) = TRUE),
					(SELECT COUNT(*) FROM events e WHERE e.company_id = c.id),
					(SELECT COUNT(*) FROM courses cr WHERE cr.company_id = c.id),
					(SELECT COUNT(*) FROM applications a JOIN vacancies v ON v.id = a.vacancy_id WHERE v.company_id = c.id AND a.status <> 'Withdrawn'),
					COALESCE((SELECT ROUND(AVG(a.match_score))::INT FROM applications a JOIN vacancies v ON v.id = a.vacancy_id WHERE v.company_id = c.id AND a.status <> 'Withdrawn'), 0)
				FROM companies c
				ORDER BY c.id ASC
			`)
			if err == nil {
				for cRows.Next() {
					var id int64
					var name, industry string
					var vacCnt, actVacCnt, evCnt, crCnt, appCnt, avgScore int
					if err := cRows.Scan(&id, &name, &industry, &vacCnt, &actVacCnt, &evCnt, &crCnt, &appCnt, &avgScore); err == nil {
						companies = append(companies, gin.H{
							"id":                     id,
							"name":                   name,
							"industry":               industry,
							"vacancies_count":        vacCnt,
							"active_vacancies_count": actVacCnt,
							"events_count":           evCnt,
							"courses_count":          crCnt,
							"applications_count":     appCnt,
							"avg_match_score":        avgScore,
						})
					}
				}
				if err := cRows.Err(); err != nil {
					log.Println("admin cRows err:", err)
				}
				cRows.Close()
			}

			// 3. Demand vs Supply по навыкам
			skillsStats := make([]gin.H, 0)
			skRows, err := db.Query(`
				SELECT
					s.name,
					(SELECT COUNT(DISTINCT vs.vacancy_id) FROM vacancy_skills vs WHERE vs.skill_id = s.id) AS demand_cnt,
					(SELECT COUNT(DISTINCT ss.student_profile_id) FROM student_skills ss WHERE ss.skill_id = s.id) AS supply_cnt
				FROM skills s
				WHERE EXISTS (SELECT 1 FROM vacancy_skills vs WHERE vs.skill_id = s.id)
				ORDER BY demand_cnt DESC, supply_cnt ASC
				LIMIT 10
			`)
			if err == nil {
				for skRows.Next() {
					var sName string
					var demandCnt, supplyCnt int
					if err := skRows.Scan(&sName, &demandCnt, &supplyCnt); err == nil {
						skillsStats = append(skillsStats, gin.H{
							"skill_name":   sName,
							"demand_count": demandCnt,
							"supply_count": supplyCnt,
						})
					}
				}
				if err := skRows.Err(); err != nil {
					log.Println("admin skRows err:", err)
				}
				skRows.Close()
			}

			c.JSON(200, gin.H{
				"kpis": gin.H{
					"total_students":     totalStudents,
					"total_companies":    totalCompanies,
					"total_vacancies":    totalVacancies,
					"active_vacancies":   activeVacancies,
					"total_applications": totalApps,
					"interviews_count":   interviewsCount,
					"approved_count":     approvedCount,
					"total_events":       totalEvents,
					"total_courses":      totalCourses,
				},
				"universities":  universities,
				"companies":     companies,
				"skills_demand": skillsStats,
			})
		})

		api.GET("/students/:id/vacancies/:vacancyId/match", matchHandler.GetMatch)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Println("server started on http://localhost:" + port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
