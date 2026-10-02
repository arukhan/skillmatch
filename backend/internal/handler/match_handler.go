package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"skillmatch-backend/internal/service"
)

type MatchHandler struct {
	service service.MatchService
}

func NewMatchHandler(service service.MatchService) *MatchHandler {
	return &MatchHandler{
		service: service,
	}
}

func (h *MatchHandler) GetMatch(c *gin.Context) {
	studentID, ok := parseID(c, "id")
	if !ok {
		return
	}

	vacancyID, ok := parseID(c, "vacancyId")
	if !ok {
		return
	}

	result, err := h.service.GetMatch(
		c.Request.Context(),
		studentID,
		vacancyID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, result)
}
