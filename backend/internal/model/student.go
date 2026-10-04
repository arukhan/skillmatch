package model

type Student struct {
	ID              int64   `json:"id" db:"id"`
	UserID          int64   `json:"user_id" db:"user_id"`
	FullName        string  `json:"full_name" db:"full_name"`
	University      *string `json:"university,omitempty" db:"university"`
	Major           *string `json:"major,omitempty" db:"major"`
	Education       *string `json:"education,omitempty" db:"education"`
	ExperienceYears float64 `json:"experience_years" db:"experience_years"`
}
type CreateStudentRequest struct {
	UserID          int64   `json:"user_id" binding:"required"`
	FullName        string  `json:"full_name" binding:"required"`
	University      *string `json:"university"`
	Major           *string `json:"major"`
	Education       *string `json:"education"`
	ExperienceYears float64 `json:"experience_years"`
}
type UpdateStudentRequest struct {
	FullName        string  `json:"full_name" binding:"required"`
	University      *string `json:"university"`
	Major           *string `json:"major"`
	Education       *string `json:"education"`
	ExperienceYears float64 `json:"experience_years"`
}
