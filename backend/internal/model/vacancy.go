package model

import "time"

type Vacancy struct {
	ID                 int64     `json:"id" db:"id"`
	CompanyID          int64     `json:"company_id" db:"company_id"`
	Title              string    `json:"title" db:"title"`
	Description        *string   `json:"description,omitempty" db:"description"`
	ExperienceRequired float64   `json:"experience_required" db:"experience_required"`
	EmploymentType     *string   `json:"employment_type,omitempty" db:"employment_type"`
	Location           *string   `json:"location,omitempty" db:"location"`
	CreatedAt          time.Time `json:"created_at" db:"created_at"`
}

type VacancySkill struct {
	VacancyID     int64   `json:"vacancy_id" db:"vacancy_id"`
	SkillID       int64   `json:"skill_id" db:"skill_id"`
	RequiredLevel *string `json:"required_level,omitempty" db:"required_level"`
	IsRequired    bool    `json:"is_required" db:"is_required"`
}

type VacancySkillResponse struct {
	ID            int64   `json:"id" db:"id"`
	Name          string  `json:"name" db:"name"`
	RequiredLevel *string `json:"required_level,omitempty" db:"required_level"`
	IsRequired    bool    `json:"is_required" db:"is_required"`
}
