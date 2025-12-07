# Project Handover Documentation: Backend Updates

**Date:** 2025-12-07
**Tech Stack:** Laravel (Filament), Spatie Permissions, Flutter (Mobile Consumer)
**Context:** Updates to User Authentication and Period Tracker (Catatan Haid) modules.

---

## 1. Module: User Authentication & Registration

### A. Database Schema Changes (`users` table)

The following columns are no longer `nullable`. They are now **mandatory**:

- `name` (string)
- `gender` (string)
- `dob` (date)

### B. Validation Rules (`UserRegisterRequest`)

The Registration API (`POST /register`) now enforces strict validation.

| Field        | Rules                                                                              | Notes                |
| :----------- | :--------------------------------------------------------------------------------- | :------------------- |
| `name`     | `required`, `string`, `max:255`                                              |                      |
| `username` | `required`, `string`, `min:3`, `max:100`, `unique:users`, `alpha_dash` | No spaces allowed.   |
| `email`    | `required`, `email`, `unique:users`                                          |                      |
| `password` | `required`, `min:8`                                                            |                      |
| `gender`   | `required`, `in:Laki-laki,Perempuan`                                           | Strict Enum.         |
| `dob`      | `required`, `date`, `before:today`                                           | Must be in the past. |

### C. Controller Logic (`UserController@register`)

1. **Role Assignment:** Immediately after user creation, the system **must** assign the Spatie role: `Pengguna`.
2. **Response:** Returns HTTP `201` with `UserResource` and a success message.
3. **Error Handling:** Validation failures throw a JSON `422` exception via `HttpResponseException`.

---

## 2. Module: Period Tracker (Catatan Haid)

**Controller:** `CatatanHaidController`
**Model:** `CatatanHaid` (`user_id`, `start_date`, `end_date`)

### A. Business Logic Rules

1. **Smart Create (Anti-Duplicate):**

   - When `POST /catatan-haid` is called, check the **latest** record for the user.
   - **IF** `input.start_date` == `latest_record.start_date`: Do **not** create a new row. Instead, update the `end_date` of the existing record.
   - **ELSE**: Create a new record.
2. **Smart Edit/Delete:**

   - For `PUT` and `DELETE` requests:
   - If `id` is provided in the body: Act on that specific ID.
   - If `id` is **null/missing**: Automatically act on the **latest** record (ordered by `start_date` DESC).
3. **Access Control:**

   - **Standard Users:** Can only view/edit their own data.
   - **Super Admin:** Can view/edit any data (via `?user_id` query param).

### B. API Endpoints Summary

| Method           | Endpoint        | Description                                                   | Key Params                                 |
| :--------------- | :-------------- | :------------------------------------------------------------ | :----------------------------------------- |
| **GET**    | `/stats`      | Dashboard data: Chart points, Avg cycle, Next predicted date. | `months` (int, default: 5)               |
| **POST**   | `/`           | Create new period log.                                        | `start_date` (req), `end_date` (opt)   |
| **GET**    | `/`           | Get current/latest active period.                             | None                                       |
| **GET**    | `/?history=1` | Get list of recent cycles.                                    | `history=1`, `months`                  |
| **PUT**    | `/`           | Update period log.                                            | `id` (opt), `start_date`, `end_date` |
| **DELETE** | `/`           | Delete period log.                                            | `id` (opt)                               |

### C. JSON Response Structure (Stats)

The AI should expect the `/stats` endpoint to return this structure for the Frontend:

```json
{
  "data": {
    "periods": [
      {
        "id": 1,
        "start_date": "2023-10-01",
        "end_date": "2023-10-07",
        "period_length": 7
      }
    ],
    "chart": {
      "start_dates": ["2023-01-01", "2023-02-01"],
      "cycle_lengths": [31]
    },
    "last_cycle_length": 31,
    "avg_cycle_length": 29.5,
    "next_period": {
      "predicted_start": "2023-03-02",
      "days_until": 5
    }
  }
}
```
