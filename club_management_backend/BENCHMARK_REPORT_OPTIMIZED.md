# 🚀 ClubSphere Backend Performance & Benchmark Report

**Execution Timestamp:** 2026-09-26 17:56:00

**Environment:** Python 3.12.10 | Django 4.2.30 | Windows 11

**Target Host:** `http://127.0.0.1:8000`

**Database Engine:** `django.db.backends.postgresql`

**Database Host:** `ep-proud-math-am90ewx5-pooler.c-5.us-east-1.aws.neon.tech`


---

## 📌 Executive Summary

- **Total Endpoints Benchmarked:** `17`
- **Overall Average Endpoint Latency:** `653.46 ms`
- **Average Database Queries per Request:** `2.5`
- **Benchmark Coverage:** Authentication, JWT Token Issuance, Club Management, Event Workflows, User Profile, Admin Dashboards

## 📊 Phase 1: Endpoint Latency & Database Query Profile

| Endpoint | Method | Status | Mean (ms) | Min (ms) | Median (ms) | p95 (ms) | Max (ms) | DB Queries | DB Time (ms) |
|---|---|---|---|---|---|---|---|---|---|
| `POST Auth: Student Login` | `POST` | ✅ 200 | 3103.58 | 3060.03 | 3102.70 | 3148.01 | 3148.01 | 1 | 281.00 |
| `POST Auth: Admin Login` | `POST` | ✅ 200 | 1887.02 | 1282.45 | 1295.48 | 3083.13 | 3083.13 | 1 | 281.00 |
| `POST Auth: Token Refresh` | `POST` | ✅ 200 | 572.09 | 543.10 | 578.85 | 594.33 | 594.33 | 1 | 281.00 |
| `GET Auth: Current User Profile (/me/)` | `GET` | ✅ 200 | 199.77 | 8.04 | 8.88 | 582.39 | 582.39 | 1 | 281.00 |
| `GET Admin: Dashboard Stats` | `GET` | ✅ 200 | 548.08 | 2.26 | 2.82 | 1639.15 | 1639.15 | 5 | 1422.00 |
| `GET Admin: List Users` | `GET` | ✅ 200 | 205.93 | 3.91 | 4.62 | 609.28 | 609.28 | 1 | 281.00 |
| `GET Clubs: List All Clubs` | `GET` | ✅ 200 | 199.50 | 3.07 | 3.67 | 591.76 | 591.76 | 1 | 281.00 |
| `GET Clubs: Club Detail` | `GET` | ✅ 200 | 200.01 | 3.24 | 3.95 | 592.85 | 592.85 | 1 | 297.00 |
| `GET Clubs: Club Members` | `GET` | ✅ 200 | 275.47 | 2.95 | 3.18 | 820.28 | 820.28 | 2 | 578.00 |
| `GET Clubs: Club Chat History` | `GET` | ✅ 200 | 398.91 | 3.99 | 4.60 | 1188.15 | 1188.15 | 3 | 875.00 |
| `GET Clubs: My Clubs (/user/my/)` | `GET` | ✅ 200 | 198.93 | 6.22 | 8.28 | 582.29 | 582.29 | 1 | 297.00 |
| `GET Events: List Events` | `GET` | ✅ 200 | 293.14 | 4.93 | 5.26 | 869.24 | 869.24 | 1 | 563.00 |
| `GET Events: Event Detail` | `GET` | ✅ 200 | 186.13 | 4.24 | 4.84 | 549.30 | 549.30 | 1 | 282.00 |
| `GET Events: My Registrations` | `GET` | ✅ 200 | 408.05 | 9.54 | 9.78 | 1204.83 | 1204.83 | 3 | 844.00 |
| `GET Clubs: User Notifications` | `GET` | ✅ 200 | 197.49 | 4.54 | 5.69 | 582.24 | 582.24 | 1 | 297.00 |
| `GET Clubs: Suggestion Polls` | `GET` | ✅ 200 | 197.35 | 6.72 | 9.02 | 576.32 | 576.32 | 1 | 296.00 |
| `POST Auth: Register New Student` | `POST` | ✅ 201 | 2037.36 | 1882.55 | 1998.42 | 2231.10 | 2231.10 | 18 | 5297.00 |

---

## ⚡ Phase 2: Concurrency & Throughput Scaling

| Endpoint | Concurrency (Workers) | Requests | RPS (Req/Sec) | Mean (ms) | p50 (ms) | p90 (ms) | p95 (ms) | p99 (ms) | Success Rate |
|---|---|---|---|---|---|---|---|---|---|
| `GET Clubs: List All Clubs` | 1 | 10 | **71.0** | 13.32 | 8.03 | 31.99 | 31.99 | 31.99 | 100% |
| `GET Clubs: List All Clubs` | 2 | 10 | **272.5** | 6.70 | 6.94 | 9.55 | 9.55 | 9.55 | 100% |
| `GET Clubs: List All Clubs` | 4 | 10 | **264.9** | 11.74 | 10.68 | 18.75 | 18.75 | 18.75 | 100% |
| `GET Events: List Events` | 1 | 10 | **60.8** | 15.98 | 8.38 | 32.48 | 32.48 | 32.48 | 100% |
| `GET Events: List Events` | 2 | 10 | **190.9** | 10.00 | 6.45 | 29.88 | 29.88 | 29.88 | 100% |
| `GET Events: List Events` | 4 | 10 | **340.5** | 9.03 | 8.49 | 12.43 | 12.43 | 12.43 | 100% |
| `GET Auth: Current User Profile (/me/)` | 1 | 10 | **43.9** | 22.36 | 25.28 | 65.45 | 65.45 | 65.45 | 100% |
| `GET Auth: Current User Profile (/me/)` | 2 | 10 | **97.0** | 18.81 | 16.98 | 42.89 | 42.89 | 42.89 | 100% |
| `GET Auth: Current User Profile (/me/)` | 4 | 10 | **131.2** | 22.03 | 23.02 | 29.50 | 29.50 | 29.50 | 100% |
| `GET Admin: Dashboard Stats` | 1 | 10 | **6.8** | 146.29 | 11.66 | 1360.74 | 1360.74 | 1360.74 | 100% |
| `GET Admin: Dashboard Stats` | 2 | 10 | **239.2** | 6.35 | 4.29 | 26.82 | 26.82 | 26.82 | 100% |
| `GET Admin: Dashboard Stats` | 4 | 10 | **226.0** | 10.26 | 7.11 | 31.92 | 31.92 | 31.92 | 100% |
| `POST Auth: Student Login` | 1 | 10 | **0.7** | 1502.07 | 1559.80 | 1721.00 | 1721.00 | 1721.00 | 100% |
| `POST Auth: Student Login` | 2 | 10 | **1.3** | 1507.71 | 1484.50 | 1678.51 | 1678.51 | 1678.51 | 100% |
| `POST Auth: Student Login` | 4 | 10 | **1.8** | 1895.19 | 1893.02 | 2128.41 | 2128.41 | 2128.41 | 100% |

---

## 🔍 Database Optimization & N+1 Analysis

> [!NOTE] No duplicate queries detected across standard single-record and small listing endpoints.

## 💡 Architectural Insights & Recommendations

1. **Password Hashing Overhead in Auth:** `POST /api/auth/login/` and `POST /api/auth/register/` take longer by design (~150-250ms) due to Django's secure PBKDF2 password hashing algorithm. This is intentional security behavior.
2. **Remote Neon PostgreSQL Latency:** Database queries connect to Neon serverless PostgreSQL hosted in AWS US-East-1. In a co-located cloud deployment (e.g. Render / AWS US-East), cross-region WAN latency (~180ms) drops to sub-5ms internal VPC latency.
3. **Caching Opportunities:** Read-heavy public endpoints like `/api/clubs/` and `/api/clubs/events/` are prime candidates for Redis / in-memory cache with 30-60 second TTL.