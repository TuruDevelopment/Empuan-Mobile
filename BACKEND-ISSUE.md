# 🔴 MASALAH DITEMUKAN: BACKEND ISSUE!

## 🎯 Situasi Saat Ini

✅ Mobile app login berhasil dengan **user_id 8** (Yongky)  
✅ Token berisi user_id 8  
❌ Data tersimpan dengan user_id 1 atau 2 ← **INI MASALAH BACKEND!**

---

## 🔍 Analisis Masalah

### Mobile App Side: ✅ SUDAH BENAR

```dart
// Request yang dikirim mobile app:
POST http://192.168.1.7:8000/api/kontakpalsus
Headers: {
  "Authorization": "Bearer eyJ0eXAi... (token user_id 8)"
  "Content-Type": "application/json"
}
Body: {
  "name": "Test",
  "phoneNumber": "08123",
  "relation": "Family"
  // ✅ TIDAK ADA user_id di body!
}
```

### Backend Side: ❌ MASIH BERMASALAH

```php
// Backend SEHARUSNYA:
public function create(Request $request) {
    $user = Auth::user();  // Ambil dari token → user_id 8
    $data = $request->validated();

    $kontakPalsu = new KontakPalsu($data);
    $kontakPalsu->user_id = $user->id;  // Set ke 8
    $kontakPalsu->save();

    return response()->json(['data' => $kontakPalsu]);
}

// Backend KEMUNGKINAN MASIH SEPERTI INI:
public function create(Request $request) {
    $kontakPalsu = KontakPalsu::create($request->all());  // ❌ Mass assignment
    // Atau hardcoded user_id = 1
    return response()->json(['data' => $kontakPalsu]);
}
```

---

## 🧪 Test Backend Sekarang

### Test 1: Cek Backend Controller

Di backend, buka file:

```
app/Http/Controllers/KontakPalsuController.php
```

Cari method `store()` atau `create()`. Pastikan seperti ini:

```php
public function store(Request $request)
{
    // Validate request
    $validated = $request->validate([
        'name' => 'required|string',
        'phoneNumber' => 'required|string',
        'relation' => 'required|string',
    ]);

    // Get authenticated user from token
    $user = Auth::user();

    // Create dengan explicit user_id assignment
    $kontakPalsu = new KontakPalsu($validated);
    $kontakPalsu->user_id = $user->id;  // ← INI PENTING!
    $kontakPalsu->save();

    return response()->json([
        'status' => 'success',
        'data' => $kontakPalsu
    ], 201);
}
```

**JANGAN seperti ini:**

```php
// ❌ SALAH:
public function store(Request $request)
{
    $kontakPalsu = KontakPalsu::create($request->all());  // Mass assignment
    return response()->json(['data' => $kontakPalsu]);
}
```

---

### Test 2: Cek Backend Model

Di backend, buka file:

```
app/Models/KontakPalsu.php
```

Pastikan `user_id` **TIDAK ADA** di `$fillable`:

```php
class KontakPalsu extends Model
{
    protected $table = 'kontak_palsus';

    // ✅ BENAR - user_id TIDAK ada di sini:
    protected $fillable = [
        'name',
        'phoneNumber',
        'relation',
    ];

    // ❌ SALAH - jika seperti ini:
    // protected $fillable = [
    //     'name',
    //     'phoneNumber',
    //     'relation',
    //     'user_id',  // ← HAPUS INI!
    // ];
}
```

---

### Test 3: Cek Middleware Authentication

Di backend, file `routes/api.php`:

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/kontakpalsus', [KontakPalsuController::class, 'store']);
});
```

Pastikan route menggunakan `auth:sanctum` middleware!

---

### Test 4: Debug di Backend

Tambahkan logging di backend controller:

```php
public function store(Request $request)
{
    $user = Auth::user();

    // Debug logging
    \Log::info('═══════════════════════════════════════════════');
    \Log::info('CREATE KONTAK PALSU - Backend Debug');
    \Log::info('───────────────────────────────────────────────');
    \Log::info('Authenticated User ID: ' . $user->id);
    \Log::info('Authenticated Username: ' . $user->username);
    \Log::info('Request Body: ' . json_encode($request->all()));
    \Log::info('═══════════════════════════════════════════════');

    $validated = $request->validate([
        'name' => 'required|string',
        'phoneNumber' => 'required|string',
        'relation' => 'required|string',
    ]);

    $kontakPalsu = new KontakPalsu($validated);
    $kontakPalsu->user_id = $user->id;
    $kontakPalsu->save();

    \Log::info('✅ Data saved with user_id: ' . $kontakPalsu->user_id);

    return response()->json(['data' => $kontakPalsu], 201);
}
```

Lalu cek file log:

```bash
tail -f storage/logs/laravel.log
```

---

## 🔧 Cara Fix Backend

### Step 1: Update Controller

```bash
# Di backend project
nano app/Http/Controllers/KontakPalsuController.php
```

Ganti method `store()`:

```php
public function store(Request $request)
{
    $validated = $request->validate([
        'name' => 'required|string',
        'phoneNumber' => 'required|string',
        'relation' => 'required|string',
    ]);

    $user = Auth::user();

    if (!$user) {
        return response()->json([
            'status' => 'error',
            'message' => 'Unauthenticated'
        ], 401);
    }

    $kontakPalsu = new KontakPalsu($validated);
    $kontakPalsu->user_id = $user->id;
    $kontakPalsu->save();

    return response()->json([
        'status' => 'success',
        'data' => $kontakPalsu
    ], 201);
}
```

### Step 2: Update Model

```bash
nano app/Models/KontakPalsu.php
```

Pastikan:

```php
protected $fillable = [
    'name',
    'phoneNumber',
    'relation',
    // user_id TIDAK ADA DI SINI!
];
```

### Step 3: Test dari Mobile

Setelah backend di-update:

1. Restart backend server
2. Di mobile app, coba create kontak palsu lagi
3. Lihat console output

Expected:

```
✅ Data saved successfully!
🆔 Saved with user_id: 8
✅ Correct user_id! (8)
```

---

## 🧪 Test Manual Backend

Test backend langsung dengan curl:

```bash
# Login dulu untuk dapat token
curl -X POST http://192.168.1.7:8000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"Yongky","password":"your_password"}'

# Copy token dari response
# Expected: {"data":{"id":8,"username":"Yongky","token":"xxx"}}

# Test create kontak palsu dengan token user 8
curl -X POST http://192.168.1.7:8000/api/kontakpalsus \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_YANG_DIDAPAT" \
  -d '{"name":"Test Manual","phoneNumber":"08999","relation":"Friend"}'

# Check response
# Expected: {"data":{"id":xxx,"user_id":8,"name":"Test Manual",...}}
```

Jika response menunjukkan `user_id: 8` ✅ Backend fixed!  
Jika response menunjukkan `user_id: 1` atau `user_id: 2` ❌ Backend masih salah!

---

## 🎯 Quick Fix Checklist untuk Backend

Di backend Laravel:

- [ ] File: `app/Http/Controllers/KontakPalsuController.php`

  - [ ] Method `store()` menggunakan `Auth::user()`
  - [ ] Explicit assignment: `$model->user_id = $user->id`
  - [ ] Tidak pakai `create($request->all())`

- [ ] File: `app/Models/KontakPalsu.php`

  - [ ] `$fillable` tidak ada `'user_id'`
  - [ ] Add `protected $guarded = ['user_id'];` jika perlu

- [ ] File: `routes/api.php`

  - [ ] Route pakai middleware `auth:sanctum`

- [ ] Test manual dengan curl
  - [ ] Response user_id = 8 (sesuai token)

---

## 📊 Summary

| Component  | Status        | Issue                            |
| ---------- | ------------- | -------------------------------- |
| Mobile App | ✅ OK         | Tidak kirim user_id, token benar |
| Token      | ✅ OK         | Berisi user_id 8 (Yongky)        |
| Backend    | ❌ **BROKEN** | Masih simpan user_id 1/2         |

**Action Required:** Fix backend controller dan model!

---

## 💡 Kenapa Ini Terjadi?

Backend kemungkinan menggunakan salah satu dari:

1. **Hardcoded user_id:**

   ```php
   $kontakPalsu->user_id = 1;  // ← Hardcoded!
   ```

2. **Mass assignment masih allow user_id:**

   ```php
   // Model masih punya user_id di $fillable
   // Request kirim user_id (tapi mobile app sudah tidak kirim)
   ```

3. **Default value di database:**

   ```sql
   -- Migration punya default value
   $table->integer('user_id')->default(1);  // ← INI MASALAH!
   ```

4. **Tidak pakai Auth::user():**
   ```php
   // Controller tidak ambil user dari token
   // Pakai session atau hardcoded
   ```

---

## 🚀 Next Steps

1. **Cek backend controller** - Update sesuai pattern di atas
2. **Cek backend model** - Remove user_id dari $fillable
3. **Test dengan curl** - Verify backend behavior
4. **Test dari mobile** - Should work after backend fixed

**Mobile app sudah 100% benar. Tinggal fix backend!** ✅
