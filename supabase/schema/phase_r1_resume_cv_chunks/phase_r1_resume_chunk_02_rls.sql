-- Phase R1 / Chunk 02
-- Resume/CV RLS. Students own their resumes; admins can inspect.

begin;

drop policy if exists p_r1_resume_profile_select on public.student_resume_profile;
create policy p_r1_resume_profile_select
on public.student_resume_profile
for select to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p_r1_resume_profile_insert on public.student_resume_profile;
create policy p_r1_resume_profile_insert
on public.student_resume_profile
for insert to authenticated
with check (public.app_phase3_uid_is_self(uid));

drop policy if exists p_r1_resume_profile_update on public.student_resume_profile;
create policy p_r1_resume_profile_update
on public.student_resume_profile
for update to authenticated
using (public.app_phase3_uid_is_self(uid))
with check (public.app_phase3_uid_is_self(uid));

drop policy if exists p_r1_resume_profile_delete on public.student_resume_profile;
create policy p_r1_resume_profile_delete
on public.student_resume_profile
for delete to authenticated
using (public.app_phase3_uid_is_self(uid));

drop policy if exists p_r1_resumes_select on public.student_resumes;
create policy p_r1_resumes_select
on public.student_resumes
for select to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p_r1_resumes_insert on public.student_resumes;
create policy p_r1_resumes_insert
on public.student_resumes
for insert to authenticated
with check (public.app_phase3_uid_is_self(uid));

drop policy if exists p_r1_resumes_update on public.student_resumes;
create policy p_r1_resumes_update
on public.student_resumes
for update to authenticated
using (public.app_phase3_uid_is_self(uid))
with check (public.app_phase3_uid_is_self(uid));

drop policy if exists p_r1_resumes_delete on public.student_resumes;
create policy p_r1_resumes_delete
on public.student_resumes
for delete to authenticated
using (public.app_phase3_uid_is_self(uid));

commit;
