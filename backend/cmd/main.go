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

func main() {
	// Load .env
	err := godotenv.Load()
	if err != nil {
		log.Fatal("failed to load .env file")
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
	studentService := service.NewStudentService(
		studentRepo,
		skillRepo,
	)

	matchService := service.NewMatchService(
		skillRepo,
		vacancyRepo,
	)

	// Handlers
	studentHandler := handler.NewStudentHandler(studentService)
	matchHandler := handler.NewMatchHandler(matchService)

	// Gin
	router := gin.Default()

	api := router.Group("/api/v1")
	{
		students := api.Group("/students")
		{
			students.POST("", studentHandler.CreateStudent)

			students.GET("/:id", studentHandler.GetStudent)

			students.PUT("/:id", studentHandler.UpdateStudent)

			students.DELETE("/:id", studentHandler.DeleteStudent)

			students.POST(
				"/:id/skills",
				studentHandler.AddSkill,
			)

			students.GET(
				"/:id/skills",
				studentHandler.GetSkills,
			)

			students.DELETE(
				"/:id/skills/:skillId",
				studentHandler.DeleteSkill,
			)
		}

		api.GET(
			"/students/:id/vacancies/:vacancyId/match",
			matchHandler.GetMatch,
		)
	}

	log.Println("server started on http://localhost:8080")

	err = router.Run(":8080")
	if err != nil {
		log.Fatal(err)
	}
}
