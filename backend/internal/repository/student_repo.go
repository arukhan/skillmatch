package repository

import (
	"context"

	"skillmatch-backend/internal/model"

	"github.com/jmoiron/sqlx"
)

type StudentRepository interface {
	Create(ctx context.Context, req model.CreateStudentRequest) (*model.Student, error)
	GetByID(ctx context.Context, id int64) (*model.Student, error)
	Update(ctx context.Context, id int64, req model.UpdateStudentRequest) (*model.Student, error)
	Delete(ctx context.Context, id int64) error
}

type studentRepository struct {
	db *sqlx.DB
}

func NewStudentRepository(db *sqlx.DB) StudentRepository {
	return &studentRepository{
		db: db,
	}
}

func (r *studentRepository) Create(
	ctx context.Context,
	req model.CreateStudentRequest,
) (*model.Student, error) {

	query := `
		INSERT INTO student_profiles (
			user_id,
			full_name,
			university,
			major,
			education,
			experience_years
		)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING
			id,
			user_id,
			full_name,
			university,
			major,
			education,
			experience_years
	`

	var student model.Student

	err := r.db.GetContext(
		ctx,
		&student,
		query,
		req.UserID,
		req.FullName,
		req.University,
		req.Major,
		req.Education,
		req.ExperienceYears,
	)

	if err != nil {
		return nil, err
	}

	return &student, nil
}

func (r *studentRepository) GetByID(
	ctx context.Context,
	id int64,
) (*model.Student, error) {

	query := `
		SELECT
			id,
			user_id,
			full_name,
			university,
			major,
			education,
			experience_years
		FROM student_profiles
		WHERE id = $1
	`

	var student model.Student

	err := r.db.GetContext(
		ctx,
		&student,
		query,
		id,
	)

	if err != nil {
		return nil, err
	}

	return &student, nil
}

func (r *studentRepository) Update(
	ctx context.Context,
	id int64,
	req model.UpdateStudentRequest,
) (*model.Student, error) {

	query := `
		UPDATE student_profiles
		SET
			full_name = $1,
			university = $2,
			major = $3,
			education = $4,
			experience_years = $5
		WHERE id = $6
		RETURNING
			id,
			user_id,
			full_name,
			university,
			major,
			education,
			experience_years
	`

	var student model.Student

	err := r.db.GetContext(
		ctx,
		&student,
		query,
		req.FullName,
		req.University,
		req.Major,
		req.Education,
		req.ExperienceYears,
		id,
	)

	if err != nil {
		return nil, err
	}

	return &student, nil
}

func (r *studentRepository) Delete(
	ctx context.Context,
	id int64,
) error {

	query := `
		DELETE FROM student_profiles
		WHERE id = $1
	`

	_, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}

	return nil
}
