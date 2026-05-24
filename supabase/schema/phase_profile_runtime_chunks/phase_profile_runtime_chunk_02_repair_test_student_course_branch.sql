-- Phase Profile Runtime / Chunk 02
-- Repairs earlier demo student rows that accidentally stored course text in branch.
-- Safe scope: known local/test accounts only.

begin;

with fixed_students as (
  select uid, auth_user_id, student_id
  from public.app_profile_state
  where official_email_key in (
    'student@test.gehu',
    'test1@gehu.ac.in',
    'test2@gehu.ac.in'
  )
)
update public.app_profile_state ps
set course = 'MCA',
    branch = 'Haldwani',
    source_updated_at = now(),
    updated_at = now()
from fixed_students fs
where ps.uid = fs.uid;

with fixed_students as (
  select uid, auth_user_id, student_id
  from public.app_profile_state
  where official_email_key in (
    'student@test.gehu',
    'test1@gehu.ac.in',
    'test2@gehu.ac.in'
  )
)
update mocks.mock_results mr
set course = 'MCA',
    branch = 'Haldwani',
    updated_at = now()
from fixed_students fs
where (mr.auth_user_id = fs.auth_user_id
       or mr.student_id = fs.student_id
       or mr.student_id = fs.uid);

commit;
