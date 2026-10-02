package handler

import (
	"database/sql"
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"skillmatch-backend/internal/model"
	"skillmatch-backend/internal/service"
)

type StudentHandler struct {
	service service.StudentService
}

func NewStudentHandler(service service.StudentService) *StudentHandler {
	return &StudentHandler{
		service: service,
	}
}

func parseID(c *gin.Context, paramName string) (int64, bool) {
	value := c.Param(paramName)

	id, err := strconv.ParseInt(value, 10, 64)
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "invalid " + paramName,
		})
		return 0, false
	}

	return id, true
}

func (h *StudentHandler) CreateStudent(c *gin.Context) {
	var req model.CreateStudentRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	student, err := h.service.CreateStudent(
		c.Request.Context(),
		req,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, student)
}

func (h *StudentHandler) GetStudent(c *gin.Context) {
	id, ok := parseID(c, "id")
	if !ok {
		return
	}

	student, err := h.service.GetStudent(
		c.Request.Context(),
		id,
	)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "student not found",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, student)
}

func (h *StudentHandler) UpdateStudent(c *gin.Context) {
	id, ok := parseID(c, "id")
	if !ok {
		return
	}

	var req model.UpdateStudentRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	student, err := h.service.UpdateStudent(
		c.Request.Context(),
		id,
		req,
	)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{
				"error": "student not found",
			})
			return
		}

		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, student)
}

func (h *StudentHandler) DeleteStudent(c *gin.Context) {
	id, ok := parseID(c, "id")
	if !ok {
		return
	}

	err := h.service.DeleteStudent(
		c.Request.Context(),
		id,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.Status(http.StatusNoContent)
}

func (h *StudentHandler) AddSkill(c *gin.Context) {
	studentID, ok := parseID(c, "id")
	if !ok {
		return
	}

	var req model.AddStudentSkillRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})
		return
	}

	err := h.service.AddSkill(
		c.Request.Context(),
		studentID,
		req,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "skill added successfully",
	})
}

func (h *StudentHandler) GetSkills(c *gin.Context) {
	studentID, ok := parseID(c, "id")
	if !ok {
		return
	}

	skills, err := h.service.GetSkills(
		c.Request.Context(),
		studentID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, skills)
}

func (h *StudentHandler) DeleteSkill(c *gin.Context) {
	studentID, ok := parseID(c, "id")
	if !ok {
		return
	}

	skillID, ok := parseID(c, "skillId")
	if !ok {
		return
	}

	err := h.service.DeleteSkill(
		c.Request.Context(),
		studentID,
		skillID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.Status(http.StatusNoContent)
}
