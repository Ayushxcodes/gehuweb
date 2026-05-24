-- Verify lookup/master seed counts

select 'stu_campus_master' as table_name, count(*) as row_count from stu_campus_master
union all
select 'stu_course_master', count(*) from stu_course_master
union all
select 'stu_branch_master', count(*) from stu_branch_master
union all
select 'stu_section_master', count(*) from stu_section_master
union all
select 'stu_specialization_master', count(*) from stu_specialization_master
union all
select 'emp_campus_master', count(*) from emp_campus_master
union all
select 'emp_department_master', count(*) from emp_department_master
union all
select 'emp_designation_master', count(*) from emp_designation_master
union all
select 'emp_role_master', count(*) from emp_role_master
order by table_name;
