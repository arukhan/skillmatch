package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"skillmatch-backend/internal/database"
	"skillmatch-backend/internal/handler"
	"skillmatch-backend/internal/repository"
	"skillmatch-backend/internal/service"
)

// Request body for adding a skill from Flutter/Postman.
type SkillRequest struct {
	Name string `json:"name"`
}

// Response returned by GET /api/v1/vacancies.
type VacancyResponse struct {
	ID                 int64    `json:"id"`
	CompanyName        string   `json:"company_name"`
	Title              string   `json:"title"`
	Description        string   `json:"description"`
	ExperienceRequired float64  `json:"experience_required"`
	EmploymentType     string   `json:"employment_type"`
	Location           string   `json:"location"`
	Skills             []string `json:"skills"`
}

func main() {
	// =========================================
	// LOAD .ENV
	// =========================================
	err := godotenv.Load()
	if err != nil {
		log.Println("failed to load .env file")
	}

	// =========================================
	// POSTGRESQL CONNECTION
	// =========================================
	db, err := database.Connect()
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	log.Println("successfully connected to PostgreSQL")

	// =========================================
	// REPOSITORIES
	// =========================================
	studentRepo := repository.NewStudentRepository(db)
	skillRepo := repository.NewSkillRepository(db)
	vacancyRepo := repository.NewVacancyRepository(db)

	// =========================================
	// SERVICES
	// =========================================
	studentService := service.NewStudentService(
		studentRepo,
		skillRepo,
	)

	matchService := service.NewMatchService(
		skillRepo,
		vacancyRepo,
	)

	// =========================================
	// HANDLERS
	// =========================================
	studentHandler := handler.NewStudentHandler(studentService)
	matchHandler := handler.NewMatchHandler(matchService)

	// =========================================
	// GIN ROUTER
	// =========================================
	router := gin.Default()

	// =========================================
	// CORS
	// Required for Flutter Web running in Edge.
	// =========================================
	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set(
			"Access-Control-Allow-Origin",
			"*",
		)

		c.Writer.Header().Set(
			"Access-Control-Allow-Methods",
			"GET, POST, PUT, DELETE, OPTIONS",
		)

		c.Writer.Header().Set(
			"Access-Control-Allow-Headers",
			"Content-Type, Authorization",
		)

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// =========================================
	// API v1
	// =========================================
	api := router.Group("/api/v1")
	{
		// =====================================
		// STUDENTS
		// =====================================
		students := api.Group("/students")
		{
			// ---------------------------------
			// STUDENT PROFILE
			// ---------------------------------

			// POST /api/v1/students
			students.POST(
				"",
				studentHandler.CreateStudent,
			)

			// GET /api/v1/students/:id
			students.GET(
				"/:id",
				studentHandler.GetStudent,
			)

			// PUT /api/v1/students/:id
			students.PUT(
				"/:id",
				studentHandler.UpdateStudent,
			)

			// DELETE /api/v1/students/:id
			students.DELETE(
				"/:id",
				studentHandler.DeleteStudent,
			)

			// =================================
			// STUDENT SKILLS
			// =================================

			// ---------------------------------
			// GET STUDENT SKILLS
			//
			// GET /api/v1/students/:id/skills
			// ---------------------------------
			students.GET("/:id/skills", func(c *gin.Context) {
				studentID := c.Param("id")

				rows, err := db.Query(`
					SELECT
						s.name
					FROM student_skills ss
					JOIN skills s
						ON s.id = ss.skill_id
					WHERE ss.student_profile_id = $1
					ORDER BY s.name
				`, studentID)

				if err != nil {
					log.Println("GET skills error:", err)

					c.JSON(
						500,
						gin.H{
							"error": err.Error(),
						},
					)
					return
				}

				defer rows.Close()

				var skills []map[string]string

				for rows.Next() {
					var name string

					err := rows.Scan(&name)
					if err != nil {
						log.Println(
							"Skill scan error:",
							err,
						)
						continue
					}

					skills = append(
						skills,
						map[string]string{
							"name": name,
						},
					)
				}

				// Return [] instead of null.
				if skills == nil {
					skills = []map[string]string{}
				}

				c.JSON(200, skills)
			})

			// ---------------------------------
			// ADD STUDENT SKILL
			//
			// POST /api/v1/students/:id/skills
			//
			// Body:
			// {
			//   "name": "Docker"
			// }
			// ---------------------------------
			students.POST("/:id/skills", func(c *gin.Context) {
				studentID := c.Param("id")

				var req SkillRequest

				if err := c.ShouldBindJSON(&req); err != nil {
					c.JSON(
						400,
						gin.H{
							"error": "invalid request",
						},
					)
					return
				}

				if req.Name == "" {
					c.JSON(
						400,
						gin.H{
							"error": "skill name is required",
						},
					)
					return
				}

				var skillID int64

				// Check whether the skill already exists.
				err := db.QueryRow(`
					SELECT id
					FROM skills
					WHERE name = $1
				`, req.Name).Scan(&skillID)

				// If it doesn't exist, create it.
				if err != nil {
					err = db.QueryRow(`
						INSERT INTO skills (name)
						VALUES ($1)
						RETURNING id
					`, req.Name).Scan(&skillID)

					if err != nil {
						log.Println(
							"Skill creation error:",
							err,
						)

						c.JSON(
							500,
							gin.H{
								"error": err.Error(),
							},
						)
						return
					}
				}

				// Attach the skill to the student profile.
				_, err = db.Exec(`
					INSERT INTO student_skills (
						student_profile_id,
						skill_id
					)
					VALUES ($1, $2)
					ON CONFLICT DO NOTHING
				`, studentID, skillID)

				if err != nil {
					log.Println(
						"Student skill insert error:",
						err,
					)

					c.JSON(
						500,
						gin.H{
							"error": err.Error(),
						},
					)
					return
				}

				c.JSON(
					200,
					gin.H{
						"status": "success",
					},
				)
			})

			// ---------------------------------
			// DELETE STUDENT SKILL
			//
			// DELETE
			// /api/v1/students/:id/skills?name=Docker
			// ---------------------------------
			students.DELETE("/:id/skills", func(c *gin.Context) {
				studentID := c.Param("id")
				skillName := c.Query("name")

				if skillName == "" {
					c.JSON(
						400,
						gin.H{
							"error": "skill name is required",
						},
					)
					return
				}

				_, err := db.Exec(`
					DELETE FROM student_skills
					WHERE student_profile_id = $1
					AND skill_id = (
						SELECT id
						FROM skills
						WHERE name = $2
					)
				`, studentID, skillName)

				if err != nil {
					log.Println(
						"Delete skill error:",
						err,
					)

					c.JSON(
						500,
						gin.H{
							"error": err.Error(),
						},
					)
					return
				}

				c.JSON(
					200,
					gin.H{
						"status": "deleted",
					},
				)
			})
		}

		// =====================================
		// VACANCIES
		// =====================================

		// GET /api/v1/vacancies
		//
		// Returns actual vacancies stored
		// in PostgreSQL together with
		// company name and required skills.
		api.GET("/vacancies", func(c *gin.Context) {
			rows, err := db.Query(`
				SELECT
					v.id,
					c.name,
					v.title,
					COALESCE(v.description, ''),
					COALESCE(v.experience_required, 0),
					COALESCE(v.employment_type, ''),
					COALESCE(v.location, '')
				FROM vacancies v
				JOIN companies c
					ON c.id = v.company_id
				ORDER BY v.id
			`)

			if err != nil {
				log.Println(
					"GET vacancies error:",
					err,
				)

				c.JSON(
					500,
					gin.H{
						"error": err.Error(),
					},
				)
				return
			}

			defer rows.Close()

			var vacancies []VacancyResponse

			for rows.Next() {
				var vacancy VacancyResponse

				err := rows.Scan(
					&vacancy.ID,
					&vacancy.CompanyName,
					&vacancy.Title,
					&vacancy.Description,
					&vacancy.ExperienceRequired,
					&vacancy.EmploymentType,
					&vacancy.Location,
				)

				if err != nil {
					log.Println(
						"Vacancy scan error:",
						err,
					)
					continue
				}

				// Get skills required by this vacancy.
				skillRows, err := db.Query(`
					SELECT
						s.name
					FROM vacancy_skills vs
					JOIN skills s
						ON s.id = vs.skill_id
					WHERE vs.vacancy_id = $1
					ORDER BY s.name
				`, vacancy.ID)

				if err != nil {
					log.Println(
						"GET vacancy skills error:",
						err,
					)

					vacancy.Skills = []string{}

					vacancies = append(
						vacancies,
						vacancy,
					)

					continue
				}

				var skills []string

				for skillRows.Next() {
					var skillName string

					if err := skillRows.Scan(&skillName); err != nil {
						log.Println(
							"Vacancy skill scan error:",
							err,
						)
						continue
					}

					skills = append(
						skills,
						skillName,
					)
				}

				skillRows.Close()

				if skills == nil {
					skills = []string{}
				}

				vacancy.Skills = skills

				vacancies = append(
					vacancies,
					vacancy,
				)
			}

			if vacancies == nil {
				vacancies = []VacancyResponse{}
			}

			c.JSON(
				200,
				vacancies,
			)
		})

		// =====================================
		// MATCH SCORE
		// =====================================

		// GET
		// /api/v1/students/:id/vacancies/:vacancyId/match
		api.GET(
			"/students/:id/vacancies/:vacancyId/match",
			matchHandler.GetMatch,
		)
	}

	// =========================================
	// START SERVER
	// =========================================
	log.Println(
		"server started on http://localhost:8080",
	)

	err = router.Run(":8080")
	if err != nil {
		log.Fatal(err)
	}
}
