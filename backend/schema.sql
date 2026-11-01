-- Удаляем старые таблицы, если они были (в правильном порядке из-за foreign key)
DROP TABLE IF EXISTS student_skills CASCADE;
DROP TABLE IF EXISTS skills CASCADE;
DROP TABLE IF EXISTS students CASCADE;

-- 1. Таблица студентов (привязана к твоему профилю во Flutter с ID = 1)
CREATE TABLE IF NOT EXISTS students (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    university VARCHAR(255) NOT NULL,
    major VARCHAR(255) NOT NULL,
    experience_years NUMERIC(3,1) NOT NULL
);

-- Добавим тестового студента (чтобы профиль во Flutter сразу открывался)
INSERT INTO students (id, full_name, university, major, experience_years)
VALUES (1, 'Zhumabek Askerbekuly', 'Kazakh-British Technical University', 'Information Systems', 1.5)
ON CONFLICT (id) DO NOTHING;

-- 2. Таблица всех возможных навыков
CREATE TABLE IF NOT EXISTS skills (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

-- 3. Таблица-связка: какой студент какими навыками владеет
CREATE TABLE IF NOT EXISTS student_skills (
    student_id INT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    skill_id INT REFERENCES skills(id) ON DELETE CASCADE,
    PRIMARY KEY (student_id, skill_id)
);