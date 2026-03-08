# Health App Version - Setup Commands

## Copy and run these commands in your backend terminal

---

## Step 1: Navigate to Backend

```bash
cd path/to/your/backend
# Example: cd C:\xampp\htdocs\empuan-backend
# Or: cd ~/projects/empuan-backend
```

---

## Step 2: Run Migrations

```bash
php artisan migrate
```

---

## Step 3: Seed BOTH Wellness AND Health Questions

```bash
# Seed wellness questions
php artisan db:seed WellnessQuestionSeeder

# Seed health questions (IMPORTANT for health app!)
php artisan db:seed HealthQuestionSeeder
```

---

## Step 4: Clear Cache

```bash
php artisan optimize:clear
```

---

## Step 5: Verify Setup

```bash
php artisan tinker
```

Then run these commands in tinker:

```php
// Check wellness questions
\App\Models\Question::where('question_type', 'wellness')->count();
// Expected: 3 or more

// Check health questions
\App\Models\Question::where('question_type', 'health')->count();
// Expected: 3 or more

// Get all health questions
\App\Models\Question::where('question_type', 'health')->with('options')->get();

exit
```

---

## Step 6: Check Routes

```bash
# Check wellness routes
php artisan route:list --path=wellness

# Check period tracking routes
php artisan route:list --path=catatan-haid
```

---

## Quick One-Liner (All Steps)

```bash
cd path/to/your/backend && php artisan migrate && php artisan db:seed WellnessQuestionSeeder && php artisan db:seed HealthQuestionSeeder && php artisan optimize:clear
```

---

## After Backend Setup - Run Flutter App

```bash
# Navigate to mobile app
cd path/to/empuan-mobile

# Get dependencies
flutter pub get

# Run app
flutter run -d emulator-5554
```

---

## Verify Registration

1. Open app
2. Go to registration
3. Register new user
4. Check console logs:

```
[REGISTRATION] Health App Version - Registering user...
[REGISTRATION] ✅ Registration successful for HEALTH app version
```

---

## Check Database

```sql
-- Check user's app version (should be 'health')
SELECT id, name, email, app_version, onboarding_completed 
FROM users 
WHERE email = 'your@test.com';
```

Expected: `app_version = 'health'`

---

## Troubleshooting

### If health questions not found:

```bash
# Re-run seeder
php artisan db:seed HealthQuestionSeeder

# Clear cache again
php artisan optimize:clear
```

### If migration fails:

```bash
# Check migration status
php artisan migrate:status

# Rollback if needed
php artisan migrate:rollback

# Try again
php artisan migrate
```

### If routes not found:

```bash
# Clear route cache
php artisan route:clear
php artisan route:cache

# Check all routes
php artisan route:list
```

---

**Status:** Ready to Run  
**App Version:** Health (Period Tracker + Wellness)
