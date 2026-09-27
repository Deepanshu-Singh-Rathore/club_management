# 🚀 ClubSphere Backend Performance & Benchmark Report

**Execution Timestamp:** 2026-09-25 19:05:20

**Environment:** Python 3.12.10 | Django 4.2.30 | Windows 11

**Target Host:** `http://127.0.0.1:8000`

**Database Engine:** `django.db.backends.postgresql`

**Database Host:** `ep-proud-math-am90ewx5-pooler.c-5.us-east-1.aws.neon.tech`


---

## 📌 Executive Summary

- **Total Endpoints Benchmarked:** `17`
- **Overall Average Endpoint Latency:** `3364.97 ms`
- **Average Database Queries per Request:** `4.9`
- **Benchmark Coverage:** Authentication, JWT Token Issuance, Club Management, Event Workflows, User Profile, Admin Dashboards

## 📊 Phase 1: Endpoint Latency & Database Query Profile

| Endpoint | Method | Status | Mean (ms) | Min (ms) | Median (ms) | p95 (ms) | Max (ms) | DB Queries | DB Time (ms) |
|---|---|---|---|---|---|---|---|---|---|
| `POST Auth: Student Login` | `POST` | ✅ 200 | 2930.80 | 2892.73 | 2897.84 | 3001.83 | 3001.83 | 1 | 297.00 |
| `POST Auth: Admin Login` | `POST` | ✅ 200 | 2933.43 | 2864.29 | 2945.69 | 2990.32 | 2990.32 | 1 | 281.00 |
| `POST Auth: Token Refresh` | `POST` | ✅ 200 | 2385.33 | 2286.47 | 2434.20 | 2435.32 | 2435.32 | 1 | 281.00 |
| `GET Auth: Current User Profile (/me/)` | `GET` | ✅ 200 | 2298.76 | 2193.97 | 2335.64 | 2366.66 | 2366.66 | 1 | 281.00 |
| `GET Admin: Dashboard Stats` | `GET` | ✅ 200 | 4012.84 | 3912.59 | 4048.25 | 4077.69 | 4077.69 | 7 | 2031.00 |
| `GET Admin: List Users` | `GET` | ✅ 200 | 2699.69 | 2617.16 | 2712.36 | 2769.55 | 2769.55 | 2 | 578.00 |
| `GET Clubs: List All Clubs` | `GET` | ✅ 200 | 2788.67 | 2672.31 | 2672.54 | 3021.16 | 3021.16 | 2 | 875.00 |
| `GET Clubs: Club Detail` | `GET` | ✅ 200 | 3192.99 | 3092.53 | 3164.60 | 3321.84 | 3321.84 | 4 | 1156.00 |
| `GET Clubs: Club Members` | `GET` | ✅ 200 | 2992.60 | 2935.40 | 2993.64 | 3048.75 | 3048.75 | 3 | 875.00 |
| `GET Clubs: Club Chat History` | `GET` | ✅ 200 | 3195.00 | 3054.76 | 3243.26 | 3287.00 | 3287.00 | 4 | 1156.00 |
| `GET Clubs: My Clubs (/user/my/)` | `GET` | ✅ 200 | 3000.62 | 2921.87 | 3011.18 | 3068.82 | 3068.82 | 3 | 891.00 |
| `GET Events: List Events` | `GET` | ✅ 200 | 9384.39 | 9175.01 | 9358.67 | 9619.50 | 9619.50 | 23 | 7312.00 |
| `GET Events: Event Detail` | `GET` | ✅ 200 | 2970.41 | 2930.53 | 2953.87 | 3026.82 | 3026.82 | 3 | 875.00 |
| `GET Events: My Registrations` | `GET` | ✅ 200 | 3731.16 | 3597.56 | 3777.95 | 3817.97 | 3817.97 | 6 | 1720.00 |
| `GET Clubs: User Notifications` | `GET` | ✅ 200 | 2578.70 | 2577.36 | 2577.50 | 2581.24 | 2581.24 | 2 | 578.00 |
| `GET Clubs: Suggestion Polls` | `GET` | ✅ 200 | 2647.40 | 2576.84 | 2657.19 | 2708.17 | 2708.17 | 2 | 578.00 |
| `POST Auth: Register New Student` | `POST` | ✅ 201 | 3461.77 | 3377.84 | 3443.10 | 3564.36 | 3564.36 | 18 | 5219.00 |

---

## ⚡ Phase 2: Concurrency & Throughput Scaling

| Endpoint | Concurrency (Workers) | Requests | RPS (Req/Sec) | Mean (ms) | p50 (ms) | p90 (ms) | p95 (ms) | p99 (ms) | Success Rate |
|---|---|---|---|---|---|---|---|---|---|
| `GET Clubs: List All Clubs` | 1 | 10 | **0.4** | 2821.17 | 2858.39 | 3051.90 | 3051.90 | 3051.90 | 100% |
| `GET Clubs: List All Clubs` | 2 | 10 | **0.7** | 2863.41 | 2911.60 | 3143.97 | 3143.97 | 3143.97 | 100% |
| `GET Clubs: List All Clubs` | 4 | 10 | **1.1** | 2943.51 | 2972.82 | 3187.06 | 3187.06 | 3187.06 | 100% |
| `GET Events: List Events` | 1 | 10 | **0.1** | 9353.73 | 9320.66 | 9757.21 | 9757.21 | 9757.21 | 100% |
| `GET Events: List Events` | 2 | 10 | **0.2** | 9351.95 | 9448.84 | 9735.16 | 9735.16 | 9735.16 | 100% |
| `GET Events: List Events` | 4 | 10 | **0.4** | 9254.99 | 9325.54 | 9645.85 | 9645.85 | 9645.85 | 100% |
| `GET Auth: Current User Profile (/me/)` | 1 | 10 | **0.4** | 2364.83 | 2393.00 | 2542.70 | 2542.70 | 2542.70 | 100% |
| `GET Auth: Current User Profile (/me/)` | 2 | 10 | **0.8** | 2358.12 | 2356.72 | 2436.30 | 2436.30 | 2436.30 | 100% |
| `GET Auth: Current User Profile (/me/)` | 4 | 10 | **1.4** | 2366.70 | 2334.57 | 2586.85 | 2586.85 | 2586.85 | 100% |
| `GET Admin: Dashboard Stats` | 1 | 10 | **0.2** | 4213.16 | 4216.23 | 4418.38 | 4418.38 | 4418.38 | 100% |
| `GET Admin: Dashboard Stats` | 2 | 10 | **0.5** | 4106.54 | 4140.74 | 4322.38 | 4322.38 | 4322.38 | 100% |
| `GET Admin: Dashboard Stats` | 4 | 10 | **0.8** | 4146.22 | 4156.79 | 4297.97 | 4297.97 | 4297.97 | 100% |
| `POST Auth: Student Login` | 1 | 10 | **0.3** | 2938.35 | 2976.43 | 3021.49 | 3021.49 | 3021.49 | 100% |
| `POST Auth: Student Login` | 2 | 10 | **0.7** | 2982.06 | 2970.24 | 3112.39 | 3112.39 | 3112.39 | 100% |
| `POST Auth: Student Login` | 4 | 10 | **1.0** | 3211.00 | 3250.91 | 3469.92 | 3469.92 | 3469.92 | 100% |

---

## 🔍 Database Optimization & N+1 Analysis

> [!WARNING] Potential duplicate queries detected in the following endpoints:

- **GET Events: My Registrations**: 2 duplicate queries (Total queries: 6)

*Recommendation:* Use `select_related()` and `prefetch_related()` on foreign key relations (e.g. `created_by`, `club`, `user`) to minimize database roundtrips.

## 💡 Architectural Insights & Recommendations

1. **Password Hashing Overhead in Auth:** `POST /api/auth/login/` and `POST /api/auth/register/` take longer by design (~150-250ms) due to Django's secure PBKDF2 password hashing algorithm. This is intentional security behavior.
2. **Remote Neon PostgreSQL Latency:** Database queries connect to Neon serverless PostgreSQL hosted in AWS US-East-1. In a co-located cloud deployment (e.g. Render / AWS US-East), cross-region WAN latency (~180ms) drops to sub-5ms internal VPC latency.
3. **Caching Opportunities:** Read-heavy public endpoints like `/api/clubs/` and `/api/clubs/events/` are prime candidates for Redis / in-memory cache with 30-60 second TTL.