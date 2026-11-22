package service

import (
	"context"
	"errors"
	"math"
	"strings"

	"skillmatch-backend/internal/model"
	"skillmatch-backend/internal/repository"
)

type MatchService interface {
	GetMatch(
		ctx context.Context,
		studentID int64,
		vacancyID int64,
	) (*model.MatchResponse, error)
}

type matchService struct {
	skillRepo   repository.SkillRepository
	vacancyRepo repository.VacancyRepository
}

func NewMatchService(
	skillRepo repository.SkillRepository,
	vacancyRepo repository.VacancyRepository,
) MatchService {
	return &matchService{
		skillRepo:   skillRepo,
		vacancyRepo: vacancyRepo,
	}
}

func levelRank(level *string) int {
	if level == nil {
		return 2 // Intermediate по умолчанию
	}
	switch strings.ToLower(strings.TrimSpace(*level)) {
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

func (s *matchService) GetMatch(
	ctx context.Context,
	studentID int64,
	vacancyID int64,
) (*model.MatchResponse, error) {
	if studentID <= 0 {
		return nil, errors.New("invalid student id")
	}
	if vacancyID <= 0 {
		return nil, errors.New("invalid vacancy id")
	}

	studentSkills, err := s.skillRepo.GetStudentSkills(ctx, studentID)
	if err != nil {
		return nil, err
	}

	vacancySkills, err := s.vacancyRepo.GetSkills(ctx, vacancyID)
	if err != nil {
		return nil, err
	}

	// Индексируем навыки студента и по ID, и по имени в нижнем регистре
	studentByID := make(map[int64]model.StudentSkillResponse)
	studentByName := make(map[string]model.StudentSkillResponse)
	for _, skill := range studentSkills {
		studentByID[skill.ID] = skill
		studentByName[strings.ToLower(strings.TrimSpace(skill.Name))] = skill
	}

	matched := make([]model.MatchSkill, 0)
	missing := make([]model.MatchSkill, 0)

	var totalWeight float64
	var earnedScore float64

	for _, vs := range vacancySkills {
		weight := 1.0
		totalWeight += weight

		studentSkill, exists := studentByID[vs.ID]
		if !exists {
			studentSkill, exists = studentByName[strings.ToLower(strings.TrimSpace(vs.Name))]
		}

		if exists {
			sRank := levelRank(studentSkill.Level)
			rRank := levelRank(vs.RequiredLevel)

			credit := 1.0
			if sRank < rRank {
				diff := rRank - sRank
				if diff == 1 {
					credit = 0.75
				} else {
					credit = 0.50
				}
			}

			earnedScore += weight * credit
			matched = append(matched, model.MatchSkill{
				ID:            vs.ID,
				Name:          vs.Name,
				StudentLevel:  studentSkill.Level,
				RequiredLevel: vs.RequiredLevel,
			})
		} else {
			missing = append(missing, model.MatchSkill{
				ID:            vs.ID,
				Name:          vs.Name,
				RequiredLevel: vs.RequiredLevel,
			})
		}
	}

	var score float64
	if totalWeight > 0 {
		score = math.Round((earnedScore / totalWeight) * 100)
	}

	return &model.MatchResponse{
		StudentID:     studentID,
		VacancyID:     vacancyID,
		MatchScore:    score,
		MatchedSkills: matched,
		MissingSkills: missing,
	}, nil
}
