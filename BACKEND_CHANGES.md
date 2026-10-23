# Backend changes needed for the redesign

The redesigned app (branch `redesign-play-compliance`) calls a few endpoints that the current production API doesn't have. Until they are deployed, the app shows a clear message instead of failing silently. Everything else uses the existing API unchanged.

**Status:** all endpoints below are implemented in `TuruDevelopment/Empuan-Back` on branch `redesign-play-compliance` (based on `dev`), with feature tests in `tests/Feature/PlayCompliance` and docs in `docs/PLAY-COMPLIANCE-API.md`. That branch also adds a web deletion page at `https://empuanapp.id/delete-account` for the Play Console Data safety form. To deploy: `php artisan migrate --force`, `php artisan db:seed --class=ModerationPermissionSeeder --force`, `php artisan permission:cache-reset`, and set `MAIL_*` and `APP_URL` so password reset emails work.

All endpoints are under `https://empuanapp.id/api` and use the same `Authorization: Bearer <token>` header unless marked public. Error responses should keep the current Laravel shape (`message`, optional `errors` map) because the app shows the first error message to the user.

## Required for Google Play

### 1. Delete account (Play requires in-app account deletion)
`POST /user/delete-account`
```json
{ "password": "current password" }
```
- `200` deletes the user and their posts, replies, comments, likes, trusted contacts, fake-call callers, chat sessions, learning progress and certificates, and revokes all tokens.
- `422` with `errors.password` when the password is wrong.

Play also asks for a web page where people can request deletion without the app. Add one and put its URL in the Play Console Data safety form.

### 2. Report content (Play UGC and AI-generated content policies)
`POST /reports`
```json
{
  "target_type": "ruang_puan_post | ruang_puan_comment | suara_puan_comment | chatbot_message",
  "target_id": "123",
  "reason": "Harassment or bullying",
  "details": "optional free text"
}
```
- For `chatbot_message`, `target_id` is `"<session_id>:<message id>"`, or `"<session_id>:<message index>"` for answers saved before Empuan AI v2 (no id).
- Store the reporter, notify moderators (admin panel list is enough), `201` on success.

### 3. Block a member (Play UGC policy)
`POST /blocks`
```json
{ "user_id": 42 }
```
- After blocking, exclude that user's posts and replies from `GET /ruang-puan`, `GET /ruang-puan/{id}/comments` and `GET /suara-puan/{id}/comments` for the blocker.

### 4. Author on Her Space posts
`GET /ruang-puan` items should include the author so the app can show names, "My posts", and block:
```json
{ "id": 1, "threadName": "…", "created_at": "2026-10-23T05:10:00Z", "like": 3, "comments_count": 2, "is_liked": false,
  "user": { "id": 42, "name": "Nadia" } }
```
Comments already return `user.name`; please add `user.id` there too.

## Account and onboarding

### 5. Forgot password (public)
`POST /password/forgot`
```json
{ "email": "ayu@mail.com" }
```
Always return `200` (don't reveal whether the email exists) and email a reset link.

### 6. Interests (replaces the wellness questionnaire)
`POST /onboarding/interests`
```json
{ "interests": ["Career and work", "Managing money"], "other": "Public speaking" }
```
The old onboarding (`/wellness/questions`, `/onboarding/submit` with activity level, sleep, fitness) is no longer used. The health-version endpoints (`/wellness/upgrade-to-health`, `/catatan-haid`) are not called anywhere in the app and can be retired. Keep `app_version: "general"` on registration.

### 7. Registration
No change, but the app now requires users to be 18 or older and sends `dob` on every sign-up. Please validate `dob` server-side too (reject under 18).

## Content
- **Learning:** please don't publish health or medical courses; the app is published from a personal developer account, which Google Play doesn't allow for health apps.
- **Daily question:** `GET /questions` is unchanged. The app shows two questions a day, rotating through active questions, and tracks answered days on the device. Health-related questions should be deactivated.
- **Empuan AI:** see "Empuan AI v2" below.
- **Places (`/untuk-puan`):** unchanged. Suggested categories: Salon & beauty, Fashion, Cafés, Co-working. Avoid "massage".

## Empuan AI v2

The full contract and deploy notes are in `docs/EMPUAN-AI.md` in `TuruDevelopment/Empuan-Back`, branch `redesign-play-compliance`. What the app uses:

- `POST /chatbot/stream` (Server-Sent Events: `meta`, `status`, `delta`, then `done` or `error`). The session id comes from `meta`; the app no longer calls `/chatbot/sessions/new` first.
- `POST /chatbot/sessions/{id}/regenerate` (same events) for Regenerate.
- `POST /chatbot/messages/{id}/feedback` for Helpful / Not helpful, with an optional reason.
- Message objects with `id`, `feedback`, `actions` (course, article, place, sos, fake_call, trusted_contacts, siren, learn, places) and `truncated`, and `title` on sessions.
- Errors as `{ code, message, retryable, retry_after }`. The app shows when to try again after `rate_limited` and turns Send off until then.

If `/chatbot/stream` returns 404 or 405 without a `code` (an older backend), the app falls back to `POST /chatbot/send`, which still answers the released app with `data.response`.
