# Quick Start Guide - Backend Updates for Dual App Support

## Changes Summary

The backend has been updated to support both:
1. **General Wellness App** - Lifestyle, activity, sleep tracking
2. **Health App** - Period tracking + wellness features

---

## Files Created/Modified

### New Files
- `app/Models/UserAnswer.php` - Model for storing user answers
- `app/Http/Controllers/WellnessController.php` - Wellness API endpoints
- `database/seeders/WellnessQuestionSeeder.php` - Wellness questions
- `database/seeders/HealthQuestionSeeder.php` - Health questions
- `WELLNESS_API_DOCUMENTATION.md` - Full API documentation

### Modified Files
- `app/Models/User.php` - Added wellness fields
- `app/Models/Question.php` - Added question_type and category
- `app/Http/Controllers/AuthController.php` - Updated registration, added onboarding
- `app/Http/Controllers/QuestionController.php` - Added filtering
- `app/Http/Controllers/CatatanHaidController.php` - Added app version checks
- `routes/api.php` - Added wellness routes
- `database/seeders/DatabaseSeeder.php` - Added new seeders

### New Migrations
- `create_user_answers_table` - Store user responses
- `add_wellness_fields_to_users_table` - User wellness profile
- `add_type_field_to_questions_table` - Question categorization

---

## Setup Steps

### 1. Run Migrations
```bash
php artisan migrate
```

### 2. Seed Questions (Optional)
```bash
php artisan db:seed WellnessQuestionSeeder
php artisan db:seed HealthQuestionSeeder
```

Or seed everything:
```bash
php artisan db:seed
```

---

## New API Endpoints

### Onboarding
- `POST /api/onboarding/submit` - Submit onboarding answers

### Wellness (Authenticated)
- `GET /api/wellness/questions` - Get questions
- `POST /api/wellness/answers` - Submit answers
- `GET /api/wellness/profile` - Get profile
- `PUT/PATCH /api/wellness/profile` - Update profile
- `GET /api/wellness/stats` - Get statistics
- `DELETE /api/wellness/answers` - Delete answers

---

## App Version Behavior

### General Version Users
- Can use all wellness endpoints ✅
- Cannot access period tracking (403 error) ❌

### Health Version Users
- Can use all wellness endpoints ✅
- Can access period tracking ✅

---

## Example Registration (General Version)

```bash
curl -X POST http://localhost:8000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Doe",
    "username": "janedoe",
    "email": "jane@example.com",
    "password": "password123",
    "gender": "female",
    "dob": "1995-05-15",
    "app_version": "general"
  }'
```

## Example Onboarding Submission

```bash
curl -X POST http://localhost:8000/api/onboarding/submit \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "answers": [
      {"question_id": 1, "option_id": 2, "answer_type": "wellness"},
      {"question_id": 2, "option_id": 5, "answer_type": "wellness"}
    ],
    "activity_level": "Moderately active",
    "sleep_quality": "No, I sleep well",
    "wellness_concerns": ["Stress management"]
  }'
```

---

## Testing Checklist

- [ ] Run migrations successfully
- [ ] Register new user with `app_version: 'general'`
- [ ] Register new user with `app_version: 'health'`
- [ ] Submit onboarding answers
- [ ] Access wellness endpoints
- [ ] Verify general version users cannot access period tracking
- [ ] Verify health version users can access period tracking
- [ ] Run seeders and verify questions are created

---

## Notes

- All existing functionality remains unchanged
- Period tracking is now restricted by `app_version`
- Questions are categorized by `question_type` (wellness/health/general)
- User answers are stored in `user_answers` table
- Wellness profile is stored directly in `users` table

For complete API documentation, see `WELLNESS_API_DOCUMENTATION.md`
