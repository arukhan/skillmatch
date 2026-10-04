package service

import (
	"context"
	"errors"

	"skillmatch-backend/internal/model"
	"skillmatch-backend/internal/repository"
)

type StudentService interface {
	CreateStudent(ctx context.Context, req model.CreateStudentRequest) (*model.Student, error)
	GetStudent(ctx context.Context, id int64) (*model.Student, error)
	UpdateStudent(ctx context.Context, id int64, req model.UpdateStudentRequest) (*model.Student, error)
	DeleteStudent(ctx context.Context, id int64) error

	AddSkill(ctx context.Context, studentID int64, req model.AddStudentSkillRequest) error
	GetSkills(ctx context.Context, studentID int64) ([]model.StudentSkillResponse, error)
	DeleteSkill(ctx context.Context, studentID int64, skillID int64) error
}

type studentService struct {
	studentRepo repository.StudentRepository
	skillRepo   repository.SkillRepository
}

func NewStudentService(
	studentRepo repository.StudentRepository,
	skillRepo repository.SkillRepository,
) StudentService {
	return &studentService{
		studentRepo: studentRepo,
		skillRepo:   skillRepo,
	}
}

func (s *studentService) CreateStudent(
	ctx context.Context,
	req model.CreateStudentRequest,
) (*model.Student, error) {

	if req.FullName == "" {
		return nil, errors.New("full name is required")
	}

	if req.ExperienceYears < 0 {
		return nil, errors.New("experience years cannot be negative")
	}

	return s.studentRepo.Create(ctx, req)
}

func (s *studentService) GetStudent(
	ctx context.Context,
	id int64,
) (*model.Student, error) {

	if id <= 0 {
		return nil, errors.New("invalid student id")
	}

	return s.studentRepo.GetByID(ctx, id)
}

func (s *studentService) UpdateStudent(
	ctx context.Context,
	id int64,
	req model.UpdateStudentRequest,
) (*model.Student, error) {

	if id <= 0 {
		return nil, errors.New("invalid student id")
	}

	if req.FullName == "" {
		return nil, errors.New("full name is required")
	}

	if req.ExperienceYears < 0 {
		return nil, errors.New("experience years cannot be negative")
	}

	return s.studentRepo.Update(ctx, id, req)
}

func (s *studentService) DeleteStudent(
	ctx context.Context,
	id int64,
) error {

	if id <= 0 {
		return errors.New("invalid student id")
	}

	return s.studentRepo.Delete(ctx, id)
}

func (s *studentService) AddSkill(
	ctx context.Context,
	studentID int64,
	req model.AddStudentSkillRequest,
) error {

	if studentID <= 0 {
		return errors.New("invalid student id")
	}

	if req.SkillID <= 0 {
		return errors.New("invalid skill id")
	}

	return s.skillRepo.AddStudentSkill(ctx, studentID, req)
}

func (s *studentService) GetSkills(
	ctx context.Context,
	studentID int64,
) ([]model.StudentSkillResponse, error) {

	if studentID <= 0 {
		return nil, errors.New("invalid student id")
	}

	return s.skillRepo.GetStudentSkills(ctx, studentID)
}

func (s *studentService) DeleteSkill(
	ctx context.Context,
	studentID int64,
	skillID int64,
) error {

	if studentID <= 0 {
		return errors.New("invalid student id")
	}

	if skillID <= 0 {
		return errors.New("invalid skill id")
	}

	return s.skillRepo.DeleteStudentSkill(
		ctx,
		studentID,
		skillID,
	)
}
