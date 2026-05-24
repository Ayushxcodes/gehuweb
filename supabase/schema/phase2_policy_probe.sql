-- Probe script: confirms policy creation works in your project
-- Safe: only creates/replaces one SELECT policy on student_core

drop policy if exists p_probe_student_core_select on student_core;

create policy p_probe_student_core_select
on student_core
for select
to authenticated
using (true);

select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename = 'student_core'
order by policyname;
