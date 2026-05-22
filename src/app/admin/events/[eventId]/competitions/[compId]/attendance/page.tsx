"use client";

import React, { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { ArrowLeft, Check, ClipboardCheck } from 'lucide-react';
import { supabase } from '@/utils/supabaseClient';

export default function CompetitionAttendancePage() {
  const params = useParams();
  const eventId = params?.eventId as string;
  const compId = params?.compId as string;
  const [rows, setRows] = useState<any[]>([]);
  const [members, setMembers] = useState<any[]>([]);
  const [selected, setSelected] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);
  const [savingTeam, setSavingTeam] = useState('');

  const membersByTeam = useMemo(() => {
    const out: Record<string, any[]> = {};
    for (const member of members) {
      if (!out[member.team_id]) out[member.team_id] = [];
      out[member.team_id].push(member);
    }
    return out;
  }, [members]);

  const load = async () => {
    setLoading(true);
    const [{ data: attendanceData, error: attendanceError }, { data: memberData, error: memberError }] = await Promise.all([
      supabase.rpc('api_event_admin_attendance_page', { p_event_id: eventId, p_comp_id: compId }),
      supabase
        .from('event_team_members')
        .select('team_id, student_id, role, status')
        .eq('event_id', eventId)
        .eq('comp_id', compId)
        .neq('status', 'REMOVED')
        .order('team_id')
        .order('role'),
    ]);
    if (attendanceError || memberError) {
      alert((attendanceError || memberError).message);
    } else {
      setRows(attendanceData || []);
      setMembers(memberData || []);
      const nextSelected: Record<string, any[]> = {};
      for (const row of attendanceData || []) {
        nextSelected[row.team_id] = row.present_student_ids || [];
      }
      setSelected(nextSelected);
    }
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, [eventId, compId]);

  const toggleStudent = (teamId: string, studentId: string) => {
    setSelected((prev) => {
      const list = new Set(prev[teamId] || []);
      if (list.has(studentId)) list.delete(studentId);
      else list.add(studentId);
      return { ...prev, [teamId]: Array.from(list) };
    });
  };

  const mark = async (teamId: string) => {
    setSavingTeam(teamId);
    try {
      const { error } = await supabase.rpc('api_event_mark_team_attendance', {
        p_event_id: eventId,
        p_comp_id: compId,
        p_team_id: teamId,
        p_present_student_ids: selected[teamId] || [],
      });
      if (error) throw error;
      await load();
    } catch (err: any) {
      alert('Attendance save failed: ' + err.message);
    } finally {
      setSavingTeam('');
    }
  };

  if (loading) return (
    <div className="page-body"><div className="skeleton" style={{ height: 320 }} /></div>
  );

  return (
    <>
      <div className="page-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-md)' }}>
          <Link href={`/admin/events/${eventId}/control`} className="btn btn-ghost btn-icon"><ArrowLeft size={20} /></Link>
          <div>
            <div className="page-title">Attendance</div>
            <div className="page-subtitle">{compId}</div>
          </div>
        </div>
      </div>

      <div className="page-body animate-fade-in-up" style={{ maxWidth: 920 }}>
        {rows.length === 0 ? (
          <div className="empty-state">
            <ClipboardCheck size={42} className="empty-state-icon" />
            <div className="empty-state-title">No teams registered yet</div>
          </div>
        ) : (
          rows.map((row) => {
            const teamMembers = membersByTeam[row.team_id] || [];
            const present = new Set(selected[row.team_id] || []);
            return (
              <div key={row.team_id} className="card" style={{ marginBottom: 'var(--space-md)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginBottom: 12 }}>
                  <div>
                    <h3 style={{ marginBottom: 4 }}>{row.team_name || row.team_id}</h3>
                    <div style={{ color: 'var(--color-text-muted)', fontSize: 'var(--font-size-xs)' }}>
                      {row.participant_type} - {row.attendance_status || 'UNMARKED'}
                    </div>
                  </div>
                  <span className="badge badge-accent">{present.size}/{teamMembers.length} present</span>
                </div>

                <div style={{ display: 'grid', gap: 8 }}>
                  {teamMembers.map((member) => (
                    <label key={member.student_id} className="card" style={{ padding: 12, display: 'flex', alignItems: 'center', gap: 10 }}>
                      <input
                        type="checkbox"
                        checked={present.has(member.student_id)}
                        onChange={() => toggleStudent(row.team_id, member.student_id)}
                      />
                      <span style={{ fontWeight: 600 }}>{member.student_id}</span>
                      <span className="badge">{member.role}</span>
                    </label>
                  ))}
                </div>

                <button className="btn btn-primary" style={{ marginTop: 12 }} onClick={() => mark(row.team_id)} disabled={savingTeam === row.team_id}>
                  <Check size={16} /> {savingTeam === row.team_id ? 'Saving...' : 'Save Attendance'}
                </button>
              </div>
            );
          })
        )}
      </div>
    </>
  );
}
