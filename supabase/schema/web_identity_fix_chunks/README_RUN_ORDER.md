# Web Identity Fix Run Order

Run these in Supabase SQL Editor:

1. `web_identity_fix_chunk_01a_core_identity.sql`
2. `web_identity_fix_chunk_01b_student_profile_state.sql`
3. `web_identity_fix_chunk_02_verify.sql`

Purpose:

- Repairs identity routing for the four Supabase Auth test accounts.
- Creates minimal linked student/admin domain rows if missing.
- Creates/repairs student/admin `app_profile_state` rows needed by web guards.
