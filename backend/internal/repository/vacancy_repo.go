package repository

import (
	"context"

	"skillmatch-backend/internal/model"

	"github.com/jmoiron/sqlx"
)

type VacancyRepository interface {
	GetByID(
		ctx context.Context,
		id int64,
	) (*model.Vacancy, error)

	GetSkills(
		ctx context.Context,
		vacancyID int64,
	) ([]model.VacancySkillResponse, error)
}

type vacancyRepository struct {
	db *sqlx.DB
}

func NewVacancyRepository(db *sqlx.DB) VacancyRepository {
	return &vacancyRepository{
		db: db,
	}
}
func (r *vacancyRepository) GetByID(
	ctx context.Context,
	id int64,
) (*model.Vacancy, error) {

	query := `
		SELECT
			id,
			company_id,
			title,
			description,
			experience_required,
			employment_type,
			location,
			created_at
		FROM vacancies
		WHERE id = $1
	`

	var vacancy model.Vacancy

	err := r.db.GetContext(
		ctx,
		&vacancy,
		query,
		id,
	)

	if err != nil {
		return nil, err
	}

	return &vacancy, nil
}
func (r *vacancyRepository) GetSkills(
	ctx context.Context,
	vacancyID int64,
) ([]model.VacancySkillResponse, error) {

	query := `
		SELECT
			s.id,
			s.name,
			vs.required_level,
			vs.is_required
		FROM vacancy_skills vs
		JOIN skills s
			ON s.id = vs.skill_id
		WHERE vs.vacancy_id = $1
		ORDER BY s.name
	`

	var skills []model.VacancySkillResponse

	err := r.db.SelectContext(
		ctx,
		&skills,
		query,
		vacancyID,
	)

	if err != nil {
		return nil, err
	}

	return skills, nil
}
