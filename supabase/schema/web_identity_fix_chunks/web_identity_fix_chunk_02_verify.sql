-- Web Identity Fix / Chunk 02
-- Expected: 4 rows, all WEB_READY.

with desired(email, expected_type) as (
  values
    ('admin@test.gehu', 'ADMIN'),
    ('student@test.gehu', 'STUDENT'),
    ('test1@gehu.ac.in', 'STUDENT'),
    ('test2@gehu.ac.in', 'STUDENT')
)
select
  d.email,
  d.expected_type,
  u.id is not null as has_auth_user,
  ai.account_type,
  ai.is_active,
  ai.student_id,
  ai.employee_id,
  p.profile_completed,
  p.verification_status,
  case
    when u.id is null then 'BLOCKED: missing auth user'
    when ai.auth_user_id is null then 'BLOCKED: missing identity'
    when ai.is_active is not true then 'BLOCKED: inactive identity'
    when ai.account_type <> d.expected_type then 'BLOCKED: wrong account type'
    when ai.account_type = 'STUDENT' and p.uid is null then 'BLOCKED: missing profile'
    else 'WEB_READY'
  end as web_gate_status
from desired d
left join auth.users u on lower(u.email) = lower(d.email)
left join public.app_user_identity ai on ai.auth_user_id = u.id
left join public.app_profile_state p on p.auth_user_id = u.id
order by d.email;

