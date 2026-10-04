package model

type Skill struct {
	ID   int64  `json:"id" db:"id"`
	Name string `json:"name" db:"name"`
}

type StudentSkill struct {
	StudentProfileID int64   `json:"student_profile_id" db:"student_profile_id"`
	SkillID          int64   `json:"skill_id" db:"skill_id"`
	Level            *string `json:"level,omitempty" db:"level"`
}

type StudentSkillResponse struct {
	ID    int64   `json:"id" db:"id"`
	Name  string  `json:"name" db:"name"`
	Level *string `json:"level,omitempty" db:"level"`
}

type AddStudentSkillRequest struct {
	SkillID int64   `json:"skill_id" binding:"required"`
	Level   *string `json:"level"`
}
