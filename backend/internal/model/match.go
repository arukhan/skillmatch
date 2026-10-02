package model

type MatchSkill struct {
	ID            int64   `json:"id"`
	Name          string  `json:"name"`
	StudentLevel  *string `json:"student_level,omitempty"`
	RequiredLevel *string `json:"required_level,omitempty"`
}

type MatchResponse struct {
	StudentID     int64        `json:"student_id"`
	VacancyID     int64        `json:"vacancy_id"`
	MatchScore    float64      `json:"match_score"`
	MatchedSkills []MatchSkill `json:"matched_skills"`
	MissingSkills []MatchSkill `json:"missing_skills"`
}
