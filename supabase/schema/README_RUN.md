# Run Guide: Phase 1 Student + Employee Schema

## Files
- SQL schema: `supabase/schema/phase1_student_employee_schema.sql`
- Runner script: `scripts/apply-supabase-schema.ps1`

## What you need from Supabase Dashboard
1. Open your Supabase project.
2. Click **Connect**.
3. Copy a Postgres connection string:
   - Prefer **Session pooler** (IPv4-friendly) for Windows local run.
   - Or use Direct connection if your network supports it.

Example format:
`postgres://postgres.[PROJECT_REF]:[PASSWORD]@[HOST].pooler.supabase.com:5432/postgres`

## Run command (PowerShell)
From project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply-supabase-schema.ps1 -DbUrl "YOUR_CONNECTION_STRING"
```

## Notes
- Script uses `psql`. Install PostgreSQL client tools if `psql` is missing.
- The SQL runs in a transaction.
- `stu_student_id` and `emp_employee_id` are immutable by trigger.
- This migration only creates schema objects; it does not move Firebase data yet.
