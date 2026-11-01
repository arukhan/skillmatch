# skillmatch
SkillMatch - AI-assisted career platform for university students


# Как запустить проект локально
# Гайд для чайников

### 1. Требования
- Go (версии 1.20+)
- Flutter (версии 3.х+)
- PostgreSQL

### 2. Настройка базы данных
1. Создайте локальную базу данных в PostgreSQL:
   ```sql
   CREATE DATABASE skillmatch_db;

Выполните SQL-скрипт из файла schema.sql, чтобы создать таблицы и тестового студента.

3. Настройка переменных окружения
Скопируйте файл .env.example и назовите его .env.

Укажите в нем свои данные для подключения к PostgreSQL (логин и пароль).