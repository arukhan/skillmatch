package repository

import (
	"context"

	"skillmatch-backend/internal/model"

	"github.com/jmoiron/sqlx"
)

type SkillRepository interface {
	AddStudentSkill(
		ctx context.Context,
		studentID int64,
		req model.AddStudentSkillRequest,
	) error

	GetStudentSkills(
		ctx context.Context,
		studentID int64,
	) ([]model.StudentSkillResponse, error)

	DeleteStudentSkill(
		ctx context.Context,
		studentID int64,
		skillID int64,
	) error
}

type skillRepository struct {
	db *sqlx.DB
}

func NewSkillRepository(db *sqlx.DB) SkillRepository {
	return &skillRepository{
		db: db,
	}
}

func (r *skillRepository) AddStudentSkill(
	ctx context.Context,
	studentID int64,
	req model.AddStudentSkillRequest,
) error {

	query := `
		INSERT INTO student_skills (
			student_profile_id,
			skill_id,
			level
		)
		VALUES ($1, $2, $3)
	`

	_, err := r.db.ExecContext(
		ctx,
		query,
		studentID,
		req.SkillID,
		req.Level,
	)

	return err
}

func (r *skillRepository) GetStudentSkills(
	ctx context.Context,
	studentID int64,
) ([]model.StudentSkillResponse, error) {

	query := `
		SELECT
			s.id,
			s.name,
			ss.level
		FROM student_skills ss
		JOIN skills s
			ON s.id = ss.skill_id
		WHERE ss.student_profile_id = $1
		ORDER BY s.name
	`

	var skills []model.StudentSkillResponse

	err := r.db.SelectContext(
		ctx,
		&skills,
		query,
		studentID,
	)

	if err != nil {
		return nil, err
	}

	return skills, nil
}
func (r *skillRepository) DeleteStudentSkill(
	ctx context.Context,
	studentID int64,
	skillID int64,
) error {

	query := `
		DELETE FROM student_skills
		WHERE student_profile_id = $1
		  AND skill_id = $2
	`

	_, err := r.db.ExecContext(
		ctx,
		query,
		studentID,
		skillID,
	)

	return err
}
