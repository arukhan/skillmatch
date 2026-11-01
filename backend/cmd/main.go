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

// Структура для приема JSON вынесена на уровень пакета
type SkillRequest struct {
	Name string `json:"name"`
}

func main() {
	// Load .env
	err := godotenv.Load()
	if err != nil {
		log.Println("failed to load .env file")
	}

	// PostgreSQL
	db, err := database.Connect()
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	log.Println("successfully connected to PostgreSQL")

	// Repositories
	studentRepo := repository.NewStudentRepository(db)
	skillRepo := repository.NewSkillRepository(db)
	vacancyRepo := repository.NewVacancyRepository(db)

	// Services
	studentService := service.NewStudentService(studentRepo, skillRepo)
	matchService := service.NewMatchService(skillRepo, vacancyRepo)

	// Handlers
	studentHandler := handler.NewStudentHandler(studentService)
	matchHandler := handler.NewMatchHandler(matchService)

	// Gin
	router := gin.Default()
	// Gin

	// === ДОБАВИТЬ ЭТОТ БЛОК (CORS Middleware) ===
	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})
	// ===========================================

	api := router.Group("/api/v1")
	{
		students := api.Group("/students")
		{
			students.POST("", studentHandler.CreateStudent)
			students.GET("/:id", studentHandler.GetStudent)
			students.PUT("/:id", studentHandler.UpdateStudent)
			students.DELETE("/:id", studentHandler.DeleteStudent)

			// =================================================================
			// ПРОТОТИПНЫЕ РОУТЫ ДЛЯ ЗАЩИТЫ (Прямая работа с БД)
			// (Старые роуты закомментированы, чтобы не было конфликтов путей)
			// students.POST("/:id/skills", studentHandler.AddSkill)
			// students.GET("/:id/skills", studentHandler.GetSkills)
			// students.DELETE("/:id/skills/:skillId", studentHandler.DeleteSkill)
			// =================================================================

			// 1. ПОЛУЧЕНИЕ НАВЫКОВ
			// 1. ПОЛУЧЕНИЕ НАВЫКОВ
			students.GET("/:id/skills", func(c *gin.Context) {
				studentID := c.Param("id")
				rows, err := db.Query(`
					SELECT s.name
					FROM skills s
					JOIN student_skills ss ON s.id = ss.skill_id
					WHERE ss.student_id = $1
				`, studentID)

				if err != nil {
					log.Println("Ошибка GET skills:", err)
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}
				defer rows.Close()

				var skills []map[string]string
				for rows.Next() {
					var name string
					if err := rows.Scan(&name); err == nil {
						skills = append(skills, map[string]string{"name": name})
					}
				}

				if skills == nil {
					skills = []map[string]string{}
				}
				c.JSON(200, skills)
			})

			// 2. ДОБАВЛЕНИЕ НАВЫКА (С защитой от дубликатов PK)
			students.POST("/:id/skills", func(c *gin.Context) {
				studentID := c.Param("id")
				var req SkillRequest
				if err := c.ShouldBindJSON(&req); err != nil {
					c.JSON(400, gin.H{"error": "Invalid request"})
					return
				}

				// Сначала проверяем, есть ли уже такой навык в таблице skills
				var skillID int
				err := db.QueryRow(`SELECT id FROM skills WHERE name = $1`, req.Name).Scan(&skillID)

				if err != nil {
					// Если навыка нет, создаем его (база сама подставит SERIAL ID)
					err = db.QueryRow(`
						INSERT INTO skills (name) VALUES ($1)
						RETURNING id`, req.Name).Scan(&skillID)

					if err != nil {
						log.Println("Ошибка создания навыка:", err)
						c.JSON(500, gin.H{"error": err.Error()})
						return
					}
				}

				// Привязываем навык к студенту
				_, err = db.Exec(`
					INSERT INTO student_skills (student_id, skill_id)
					VALUES ($1, $2) ON CONFLICT DO NOTHING`, studentID, skillID)

				if err != nil {
					log.Println("Ошибка привязки навыка:", err)
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}

				c.JSON(200, gin.H{"status": "success"})
			})

			// 3. УДАЛЕНИЕ НАВЫКА
			students.DELETE("/:id/skills", func(c *gin.Context) {
				studentID := c.Param("id")
				skillName := c.Query("name")

				_, err := db.Exec(`
					DELETE FROM student_skills
					WHERE student_id = $1 AND skill_id = (SELECT id FROM skills WHERE name = $2)
				`, studentID, skillName)

				if err != nil {
					log.Println("Ошибка удаления навыка:", err)
					c.JSON(500, gin.H{"error": err.Error()})
					return
				}

				c.JSON(200, gin.H{"status": "deleted"})
			})
		}

		api.GET("/students/:id/vacancies/:vacancyId/match", matchHandler.GetMatch)
	}

	log.Println("server started on http://localhost:8080")

	err = router.Run(":8080")
	if err != nil {
		log.Fatal(err)
	}
}
