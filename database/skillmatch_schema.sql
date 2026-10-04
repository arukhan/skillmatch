-- =========================================
-- 1. USERS
-- =========================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,

    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,

    role VARCHAR(50) NOT NULL
        CHECK (role IN ('STUDENT', 'COMPANY')),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =========================================
-- 2. STUDENT PROFILES
-- =========================================

CREATE TABLE student_profiles (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL UNIQUE,

    full_name VARCHAR(255) NOT NULL,
    university VARCHAR(255),
    major VARCHAR(255),
    education TEXT,
    experience_years DECIMAL(4,1) DEFAULT 0
        CHECK (experience_years >= 0),

    CONSTRAINT fk_student_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);


-- =========================================
-- 3. COMPANIES
-- =========================================

CREATE TABLE companies (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL UNIQUE,

    name VARCHAR(255) NOT NULL,
    description TEXT,
    website VARCHAR(255),

    CONSTRAINT fk_company_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);


-- =========================================
-- 4. VACANCIES
-- =========================================

CREATE TABLE vacancies (
    id BIGSERIAL PRIMARY KEY,

    company_id BIGINT NOT NULL,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    experience_required DECIMAL(4,1) DEFAULT 0
        CHECK (experience_required >= 0),

    employment_type VARCHAR(100),
    location VARCHAR(255),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_vacancy_company
        FOREIGN KEY (company_id)
        REFERENCES companies(id)
        ON DELETE CASCADE
);


-- =========================================
-- 5. SKILLS
-- =========================================

CREATE TABLE skills (
    id BIGSERIAL PRIMARY KEY,

    name VARCHAR(150) NOT NULL UNIQUE
);


-- =========================================
-- 6. STUDENT SKILLS
-- =========================================

CREATE TABLE student_skills (
    student_profile_id BIGINT NOT NULL,
    skill_id BIGINT NOT NULL,

    level VARCHAR(50),

    PRIMARY KEY (student_profile_id, skill_id),

    CONSTRAINT fk_student_skill_student
        FOREIGN KEY (student_profile_id)
        REFERENCES student_profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_student_skill_skill
        FOREIGN KEY (skill_id)
        REFERENCES skills(id)
        ON DELETE CASCADE
);


-- =========================================
-- 7. VACANCY SKILLS
-- =========================================

CREATE TABLE vacancy_skills (
    vacancy_id BIGINT NOT NULL,
    skill_id BIGINT NOT NULL,

    required_level VARCHAR(50),
    is_required BOOLEAN NOT NULL DEFAULT TRUE,

    PRIMARY KEY (vacancy_id, skill_id),

    CONSTRAINT fk_vacancy_skill_vacancy
        FOREIGN KEY (vacancy_id)
        REFERENCES vacancies(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_vacancy_skill_skill
        FOREIGN KEY (skill_id)
        REFERENCES skills(id)
        ON DELETE CASCADE
);


-- =========================================
-- 8. APPLICATIONS
-- =========================================

CREATE TABLE applications (
    id BIGSERIAL PRIMARY KEY,

    student_profile_id BIGINT NOT NULL,
    vacancy_id BIGINT NOT NULL,

    status VARCHAR(50) NOT NULL DEFAULT 'PENDING'
        CHECK (
            status IN (
                'PENDING',
                'REVIEWED',
                'ACCEPTED',
                'REJECTED'
            )
        ),

    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_application_student
        FOREIGN KEY (student_profile_id)
        REFERENCES student_profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_application_vacancy
        FOREIGN KEY (vacancy_id)
        REFERENCES vacancies(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_student_vacancy_application
        UNIQUE (student_profile_id, vacancy_id)
);


-- =========================================
-- INDEXES
-- =========================================

CREATE INDEX idx_vacancies_company_id
    ON vacancies(company_id);

CREATE INDEX idx_student_skills_skill_id
    ON student_skills(skill_id);

CREATE INDEX idx_vacancy_skills_skill_id
    ON vacancy_skills(skill_id);

CREATE INDEX idx_applications_student_id
    ON applications(student_profile_id);

CREATE INDEX idx_applications_vacancy_id
    ON applications(vacancy_id);