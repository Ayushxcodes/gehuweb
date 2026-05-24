-- Verify SELECT grants for authenticated on all phase-2 tables
select table_name
from information_schema.tables t
where t.table_schema = 'public'
  and (
    t.table_name = 'app_user_identity'
    or t.table_name like 'stu\_%' escape '\'
    or t.table_name like 'emp\_%' escape '\'
    or t.table_name like 'student\_%' escape '\'
    or t.table_name like 'employee\_%' escape '\'
  )
  and has_table_privilege('authenticated', format('public.%I', t.table_name), 'SELECT')
order by table_name;
