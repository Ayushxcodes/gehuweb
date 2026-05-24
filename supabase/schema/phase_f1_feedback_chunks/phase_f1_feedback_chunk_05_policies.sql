-- Phase F1 / Chunk 05
-- Feedback table policies.

begin;

do $$
declare
  t text;
begin
  for t in select unnest(array[
    'feedback_templates','feedback_template_questions','feedback_teachers'
  ])
  loop
    execute format('drop policy if exists p_f1_%s_admin on public.%I', t, t);
    execute format('create policy p_f1_%s_admin on public.%I for all to authenticated using (public.app_phase3_is_admin()) with check (public.app_phase3_is_admin())', t, t);
  end loop;
end $$;

drop policy if exists p_f1_cycles_select on public.feedback_cycles;
create policy p_f1_cycles_select on public.feedback_cycles
for select to authenticated
using (public.app_phase3_is_admin() or public.app_feedback_cycle_visible_to_current_user(cycle_id));

drop policy if exists p_f1_cycles_admin on public.feedback_cycles;
create policy p_f1_cycles_admin on public.feedback_cycles
for all to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

drop policy if exists p_f1_entries_select on public.feedback_cycle_entries;
create policy p_f1_entries_select on public.feedback_cycle_entries
for select to authenticated
using (public.app_phase3_is_admin() or public.app_feedback_cycle_visible_to_current_user(cycle_id));

drop policy if exists p_f1_entries_admin on public.feedback_cycle_entries;
create policy p_f1_entries_admin on public.feedback_cycle_entries
for all to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

drop policy if exists p_f1_questions_select on public.feedback_cycle_entry_questions;
create policy p_f1_questions_select on public.feedback_cycle_entry_questions
for select to authenticated
using (public.app_phase3_is_admin() or public.app_feedback_cycle_visible_to_current_user(cycle_id));

drop policy if exists p_f1_questions_admin on public.feedback_cycle_entry_questions;
create policy p_f1_questions_admin on public.feedback_cycle_entry_questions
for all to authenticated
using (public.app_phase3_is_admin())
with check (public.app_phase3_is_admin());

drop policy if exists p_f1_submissions_select on public.feedback_submissions;
create policy p_f1_submissions_select on public.feedback_submissions
for select to authenticated
using (public.app_phase3_is_admin() or public.app_phase3_uid_is_self(uid));

drop policy if exists p_f1_submissions_insert on public.feedback_submissions;
-- No direct insert policy on submissions.
-- The submit RPC writes tracker + anonymous response together atomically.

commit;
