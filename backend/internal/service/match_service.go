package service

import (
	"context"
	"errors"

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

	studentSkills, err := s.skillRepo.GetStudentSkills(
		ctx,
		studentID,
	)
	if err != nil {
		return nil, err
	}

	vacancySkills, err := s.vacancyRepo.GetSkills(
		ctx,
		vacancyID,
	)
	if err != nil {
		return nil, err
	}

	studentSkillMap := make(
		map[int64]model.StudentSkillResponse,
	)

	for _, skill := range studentSkills {
		studentSkillMap[skill.ID] = skill
	}

	var matched []model.MatchSkill
	var missing []model.MatchSkill

	requiredCount := 0
	matchedCount := 0

	for _, vacancySkill := range vacancySkills {

		if !vacancySkill.IsRequired {
			continue
		}

		requiredCount++

		studentSkill, exists :=
			studentSkillMap[vacancySkill.ID]

		if exists {

			matchedCount++

			matched = append(
				matched,
				model.MatchSkill{
					ID:            vacancySkill.ID,
					Name:          vacancySkill.Name,
					StudentLevel:  studentSkill.Level,
					RequiredLevel: vacancySkill.RequiredLevel,
				},
			)

		} else {

			missing = append(
				missing,
				model.MatchSkill{
					ID:            vacancySkill.ID,
					Name:          vacancySkill.Name,
					RequiredLevel: vacancySkill.RequiredLevel,
				},
			)
		}
	}

	var score float64

	if requiredCount > 0 {
		score =
			float64(matchedCount) /
				float64(requiredCount) *
				100
	}

	response := &model.MatchResponse{
		StudentID:     studentID,
		VacancyID:     vacancyID,
		MatchScore:    score,
		MatchedSkills: matched,
		MissingSkills: missing,
	}

	return response, nil
}
