# Panduan Integrasi React Frontend & Laravel Backend

## Daftar Isi
1. [Setup Awal](#setup-awal)
2. [Konfigurasi CORS & Sanctum](#konfigurasi-cors--sanctum)
3. [API Client & Axios](#api-client--axios)
4. [Authentication Flow](#authentication-flow)
5. [Contoh Penggunaan](#contoh-penggunaan)
6. [Troubleshooting](#troubleshooting)

---

## Setup Awal

### Backend (Laravel)
```bash
# 1. Install dependencies
cd tracer-study-backend
composer install

# 2. Setup database
cp .env.example .env.local
php artisan migrate
php artisan db:seed

# 3. Generate app key (jika belum)
php artisan key:generate

# 4. Start server (port 8000)
php artisan serve
```

### Frontend (React)
```bash
# 1. Install dependencies
cd fe-tracer-study
npm install

# 2. Create .env.local
cat > .env.local << EOF
VITE_API_URL=http://localhost:8000/api
VITE_APP_URL=http://localhost:5173
EOF

# 3. Start dev server (port 5173)
npm run dev
```

---

## Konfigurasi CORS & Sanctum

### CORS di Laravel
File: `config/cors.php` sudah dikonfigurasi untuk:
- ✅ Accept requests dari `http://localhost:5173` (React dev server)
- ✅ Accept requests dari `http://localhost:8000` (Laravel server)
- ✅ Send credentials dengan CORS requests
- ✅ Accept semua headers yang diperlukan

### Sanctum Configuration
File: `config/sanctum.php` sudah tersetup dengan:
```php
'stateful' => [
    'localhost:5173',    // React dev server
    'localhost:8000',    // Laravel
    '127.0.0.1:5173',
    '127.0.0.1:8000',
]
```

---

## API Client & Axios

### Struktur File
```
src/lib/
├── apiClient.ts      ← Axios instance & interceptors
└── ...
```

### Fitur apiClient.ts
```typescript
// Auto-add Bearer token dari localStorage
// Auto-redirect ke login jika token expired (401)
// CORS enabled dengan credentials
// Generic methods: get(), post(), put(), delete()
// Service methods: login(), logout(), getMe(), getPrograms(), etc.
```

### Penggunaan Dasar
```typescript
import { apiService } from "@/lib/apiClient";

// Login
const response = await apiService.login("user@example.com", "password");
// Token otomatis disimpan di localStorage

// Get data
const programs = await apiService.getPrograms();

// Generic GET
const data = await apiService.get("/some-endpoint");

// Logout
await apiService.logout();
```

---

## Authentication Flow

### 1. Login Flow

**Frontend → Backend**
```typescript
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Backend Response**
```json
{
  "message": "Login successful",
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com",
    "role": "admin",
    "token": "1|AbCdEf..."
  }
}
```

**Frontend Action**
```typescript
// Token disimpan di localStorage
localStorage.setItem('sanctum_token', response.data.token);

// Header otomatis ditambahkan ke setiap request:
// Authorization: Bearer 1|AbCdEf...
```

### 2. Protected Routes
```typescript
// Gunakan ProtectedRoute untuk halaman yang memerlukan auth
<Route 
  path="/dashboard" 
  element={
    <ProtectedRoute requiredRole="admin">
      <AdminDashboard />
    </ProtectedRoute>
  } 
/>
```

### 3. Logout
```typescript
await apiService.logout();
// localStorage cleared
// Redirect ke login
```

---

## Contoh Penggunaan

### Example 1: Login Page Integration
```typescript
// pages/Login.tsx
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/hooks/useAuth";

export const LoginPage = () => {
  const navigate = useNavigate();
  const { login, isLoading } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await login(email, password);
      navigate("/dashboard");
    } catch (error) {
      // Error toast sudah ditangani di hook
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input 
        type="email" 
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <input 
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
      />
      <button disabled={isLoading}>
        {isLoading ? "Loading..." : "Login"}
      </button>
    </form>
  );
};
```

### Example 2: Fetch Data dari Backend
```typescript
// components/ProgramList.tsx
import { useEffect, useState } from "react";
import { apiService } from "@/lib/apiClient";

export const ProgramList = () => {
  const [programs, setPrograms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchPrograms = async () => {
      try {
        const data = await apiService.getPrograms();
        setPrograms(data);
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchPrograms();
  }, []);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <ul>
      {programs.map((program) => (
        <li key={program.id}>{program.name}</li>
      ))}
    </ul>
  );
};
```

### Example 3: Create/Update dengan Error Handling
```typescript
// pages/ProgramForm.tsx
const handleSubmit = async (data: any) => {
  try {
    if (editId) {
      await apiService.updateProgram(editId, data);
      toast({ title: "Update berhasil" });
    } else {
      await apiService.createProgram(data);
      toast({ title: "Create berhasil" });
    }
    navigate("/programs");
  } catch (error: any) {
    const message = error.response?.data?.message || "Gagal simpan";
    toast({ title: "Error", description: message, variant: "destructive" });
  }
};
```

---

## Database Setup

### PostgreSQL Connection
```bash
# Buat database
sudo -u postgres psql
CREATE DATABASE tracer_study;
CREATE USER tracer_user WITH PASSWORD 'password123';
ALTER ROLE tracer_user SET client_encoding TO 'utf8';
ALTER ROLE tracer_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE tracer_user SET default_transaction_deferrable TO on;
ALTER ROLE tracer_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE tracer_study TO tracer_user;
```

### .env Backend
```
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=tracer_study
DB_USERNAME=tracer_user
DB_PASSWORD=password123
```

### Run Migrations
```bash
php artisan migrate --seed
```

---

## Troubleshooting

### ❌ CORS Error: "Access to XMLHttpRequest blocked"
**Penyebab:** Frontend URL tidak ada di CORS_ALLOWED_ORIGINS

**Solusi:**
```bash
# Update .env.local backend
CORS_ALLOWED_ORIGINS=http://localhost:5173,http://localhost:8000
```

### ❌ 401 Unauthorized
**Penyebab:** Token expired atau tidak dikirim

**Solusi:**
```typescript
// apiClient.ts sudah handle ini, cek localStorage
const token = localStorage.getItem('sanctum_token');
console.log('Token:', token); // Harus ada token
```

### ❌ Token tidak disimpan setelah login
**Penyebab:** Response data structure tidak sesuai

**Solusi:** Pastikan response dari `/api/auth/login` memiliki struktur:
```json
{
  "message": "...",
  "data": {
    "token": "1|AbCdEf..."
  }
}
// ATAU
{
  "token": "1|AbCdEf..."
}
```

Update `apiService.login()` jika response structure berbeda:
```typescript
login: async (email: string, password: string) => {
  const response = await apiClient.post("/auth/login", { email, password });
  const token = response.data.token || response.data.data.token;
  if (token) {
    localStorage.setItem("sanctum_token", token);
  }
  return response.data;
},
```

### ❌ Token otomatis hilang
**Penyebab:** API response 401

**Solusi:** Cek API endpoint, pastikan route protected dengan `auth:sanctum` middleware:
```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
});
```

---

## API Routes yang Sudah Tersedia

### Public Routes
```
POST   /api/auth/login                    → Login
```

### Protected Routes (Perlu token)
```
POST   /api/auth/logout                   → Logout
GET    /api/auth/me                       → Get current user

GET    /api/programs                      → Get all programs
GET    /api/programs/{id}                 → Get program by ID
POST   /api/programs                      → Create program (admin only)
PUT    /api/programs/{id}                 → Update program (admin only)
DELETE /api/programs/{id}                 → Delete program (admin only)
```

---

## Next Steps

1. ✅ Setup CORS & Sanctum
2. ✅ Install Axios
3. ✅ Buat API Client
4. ✅ Buat Auth Hook
5. ⏳ Update Login Page untuk gunakan API
6. ⏳ Update Dashboard untuk fetch real data
7. ⏳ Add more API endpoints sesuai kebutuhan
8. ⏳ Add error boundary untuk error handling
9. ⏳ Add loading states & optimistic updates
10. ⏳ Add data caching dengan React Query

---

## Referensi

- [Laravel Sanctum Docs](https://laravel.com/docs/11.x/sanctum)
- [Axios Docs](https://axios-http.com/)
- [Vite Env Variables](https://vitejs.dev/guide/env-and-modes.html)
- [React Router Protected Routes](https://reactrouter.com/en/main/start/tutorial)
