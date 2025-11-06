# 🧪 Testing Steps - User ID Fix

## ⚠️ CRITICAL: Read This First!

Masalahnya BUKAN di code mobile app. Code sudah benar!

**MASALAHNYA:** Anda masih login dengan **user lama (admin/tes dengan user_id 1/2)**

---

## 📝 Step-by-Step Testing

### **Step 1: Stop & Clear Everything**

```bash
# Stop running app
flutter run -d emulator-5554
# Press 'q' to quit

# Clear app data di emulator
Settings → Apps → Empuan → Storage → Clear Data
```

### **Step 2: Reinstall App (Fresh Start)**

```bash
# Di terminal
flutter clean
flutter pub get
flutter run -d emulator-5554
```

### **Step 3: Watch Console Output**

Saat app start, Anda HARUS melihat output ini:

```
╔════════════════════════════════════════════════════════╗
║       🔒 SECURITY UPDATE - FORCE LOGOUT               ║
╠════════════════════════════════════════════════════════╣
║  Old version: none
║  New version: 1.1.1
║  Action: Clearing all authentication data...          ║
╚════════════════════════════════════════════════════════╝
[SECURITY] ✅ Logout complete - Please login again
[SECURITY] ⚠️  DO NOT use old users (admin/tes)
[SECURITY] ✅ Use: Michael (ID 7) or Yongky (ID 8)
```

**Jika TIDAK muncul:** Clear data lagi!

---

### **Step 4: Login dengan User yang BENAR**

❌ **JANGAN login dengan:**

- Username: admin (user_id: 1)
- Username: tes (user_id: 2)

✅ **HARUS login dengan:**

- **Username: Michael** (user_id: 7)
- **Username: Yongky** (user_id: 8)

---

### **Step 5: Verify Login**

Setelah login, console HARUS menampilkan:

```
╔════════════════════════════════════════════════════════╗
║           ✅ LOGIN SUCCESSFUL                          ║
╠════════════════════════════════════════════════════════╣
║  Username: Michael
║  User ID:  7
║  Token:    eyJ0eXAiOiJKV1QiLCJhbGciOiJI...
╠════════════════════════════════════════════════════════╣
║  ✅ CORRECT USER! Data will save with user_id 7     ║
╚════════════════════════════════════════════════════════╝
```

**⚠️ Jika muncul ini:**

```
║  ⚠️  WARNING: OLD USER DETECTED!                       ║
║  ⚠️  User ID 1 is from old system                   ║
```

→ **LOGOUT IMMEDIATELY dan login dengan Michael/Yongky!**

---

### **Step 6: Test Create Data**

1. Buka menu "Emergency Contact"
2. Tambah kontak baru
3. **PERHATIKAN CONSOLE OUTPUT:**

```
═══════════════════════════════════════════════════════
🔍 CREATE EMERGENCY CONTACT - Debug Info:
───────────────────────────────────────────────────────
Request URL: http://192.168.8.48:8000/api/kontakamans
Request Body: {"name":"Test","phoneNumber":"08123","relation":"Family"}
Token (first 30 chars): eyJ0eXAiOiJKV1QiLCJhbGciOiJI...
═══════════════════════════════════════════════════════
─────────────────────────────────────────────────────
📡 Response Status: 201
📦 Response Body: {"data":{"id":123,"user_id":7,...}}
───────────────────────────────────────────────────────
✅ Data saved successfully!
🆔 Saved with user_id: 7
✅ Correct user_id! (7)
═══════════════════════════════════════════════════════
```

**✅ Jika user_id = 7 atau 8:** BERHASIL!
**❌ Jika user_id = 1 atau 2:** LOGOUT dan login ulang!

---

### **Step 7: Verify Database**

```sql
-- Di backend database
SELECT id, user_id, name, phoneNumber, created_at
FROM kontak_amen
ORDER BY id DESC
LIMIT 5;
```

**Expected Result:**

```
| id  | user_id | name         | phoneNumber | created_at          |
|-----|---------|--------------|-------------|---------------------|
| 125 | 7       | Test Contact | 081234567   | 2025-11-06 10:30:00 |
```

**✅ user_id = 7 atau 8:** CORRECT!
**❌ user_id = 1 atau 2:** Still using wrong token!

---

## 🔍 Troubleshooting

### Problem: "Masih user_id 1 atau 2"

**Cause:** Anda masih login dengan user admin/tes

**Solution:**

1. Di app: Settings → Logout
2. Clear app data
3. Reopen app
4. Login dengan **Michael** atau **Yongky**

---

### Problem: "Console tidak menampilkan output debug"

**Cause:** Flutter tidak menampilkan print statements

**Solution:**

```bash
# Run dengan verbose
flutter run -d emulator-5554 -v

# Atau lihat logcat
adb logcat | grep -E "SECURITY|LOGIN|CREATE"
```

---

### Problem: "Backend menolak request - 401 Unauthorized"

**Cause:** Token invalid atau expired

**Solution:**

1. Logout dari app
2. Login ulang
3. Token baru akan di-generate

---

### Problem: "Backend masih simpan user_id 1/2 meskipun token user 7/8"

**Cause:** BACKEND BELUM DIPERBAIKI!

**Solution:**
Cek backend code:

```php
// Backend controller HARUS seperti ini:
public function create(Request $request) {
    $user = Auth::user();  // Get user from token
    $data = $request->validated();

    $model = new Model($data);
    $model->user_id = $user->id;  // EXPLICIT assignment
    $model->save();

    return response()->json(['data' => $model]);
}

// Model HARUS seperti ini:
protected $fillable = ['name', 'phoneNumber', 'relation'];
// user_id TIDAK BOLEH ada di $fillable!
```

---

## 📊 Quick Checklist

- [ ] App di-clear data
- [ ] App di-reinstall (flutter clean + run)
- [ ] Console menampilkan "FORCE LOGOUT"
- [ ] Login dengan **Michael** (bukan admin)
- [ ] Console menampilkan "User ID: 7"
- [ ] Create data baru
- [ ] Console menampilkan "Saved with user_id: 7"
- [ ] Database menunjukkan user_id = 7

**Jika semua ✅, masalah SOLVED!**

---

## 🎯 Expected Behavior

### Correct Flow:

1. App start → Force logout → Login page
2. Login "Michael" → Token with user_id 7
3. Create data → Backend saves with user_id 7
4. Database shows user_id 7 ✅

### Wrong Flow (Your Current Issue):

1. App start → Already logged in as admin
2. Token still has user_id 1
3. Create data → Backend saves with user_id 1
4. Database shows user_id 1 ❌

**The fix: MUST logout and login with Michael/Yongky!**

---

## 📞 Still Having Issues?

Check these:

1. **Backend logs:** Is backend receiving correct token?
2. **Database:** Check users table - do Michael/Yongky exist?
3. **Token payload:** Decode JWT token - what user_id is inside?
4. **Network:** Is app reaching correct backend (192.168.8.48)?

**To decode JWT token:**

```bash
# Copy token from console
# Paste to: https://jwt.io
# Check payload section for "user_id" or "sub"
```
