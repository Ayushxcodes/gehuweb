-- Verify phase 2 read-access policy baseline

-- 1) Policy count
select count(*) as policy_count
from pg_policies
where schemaname = 'public'
  and (
    tablename = 'app_user_identity'
    or tablename like 'stu\_%' escape '\'
    or tablename like 'emp\_%' escape '\'
    or tablename like 'student\_%' escape '\'
    or tablename like 'employee\_%' escape '\'
  );

-- 2) Policy matrix
select
  tablename,
  policyname,
  roles,
  cmd
from pg_policies
where schemaname = 'public'
  and (
    tablename = 'app_user_identity'
    or tablename like 'stu\_%' escape '\'
    or tablename like 'emp\_%' escape '\'
    or tablename like 'student\_%' escape '\'
    or tablename like 'employee\_%' escape '\'
  )
order by tablename, policyname;
