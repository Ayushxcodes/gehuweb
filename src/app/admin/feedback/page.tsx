"use client";

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { supabase } from '../../../utils/supabaseClient';
import { ArrowLeft, AlertCircle, Plus, BarChart2, Users, ChevronRight } from 'lucide-react';

export default function AdminFeedbackPage() {
  const [tab, setTab] = useState('cycles'); // cycles | create | results | appeals
  const [cycles, setCycles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCycle, setSelectedCycle] = useState<any>(null);
  const [entrySummary, setEntrySummary] = useState<any[]>([]);
  const [summaryLoading, setSummaryLoading] = useState(false);

  useEffect(() => { fetchCycles(); }, []);

  const fetchCycles = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('feedback_cycles')
        .select('cycle_id, header_label, target_key, status, active, published_at, created_at')
        .order('created_at', { ascending: false });
      if (error) throw error;
      setCycles(data || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const viewResults = async (cycle: any) => {
    setSelectedCycle(cycle);
    setTab('results');
    setSummaryLoading(true);
    try {
      const { data, error } = await supabase.rpc('api_feedback_admin_entry_summary', { p_cycle_id: cycle.cycle_id });
      if (error) throw error;
      setEntrySummary(data || []);
    } catch (err: any) {
      console.error(err);
      alert('Error loading results: ' + (err?.message || String(err)));
    } finally {
      setSummaryLoading(false);
    }
  };

  return (
    <>
      <div className="page-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-md)' }}>
          <Link href="/admin" className="btn btn-ghost btn-icon"><ArrowLeft size={20} /></Link>
          <div>
            <div className="page-title">Feedback Management</div>
            <div className="page-subtitle">Faculty feedback cycles and results</div>
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 8, padding: '0 var(--space-xl)', borderBottom: '1px solid var(--color-border)', marginBottom: 'var(--space-lg)' }}>
        {[{ id: 'cycles', label: 'Cycles' }, { id: 'appeals', label: 'Profile Appeals' }].map(t => (
          <button key={t.id} onClick={() => setTab(t.id)} className={`btn btn-sm ${tab === t.id ? 'btn-primary' : 'btn-ghost'}`} style={{ borderRadius: '4px 4px 0 0' }}>{t.label}</button>
        ))}
      </div>

      <div className="page-body animate-fade-in-up">
        {tab === 'cycles' && (
          <>
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 'var(--space-lg)' }}>
              <Link href="/admin/feedback/create" className="btn btn-primary"><Plus size={16} /> Create Feedback Cycle</Link>
            </div>

            {loading ? (
              [1,2,3].map(i => <div key={i} className="skeleton" style={{ height: 80, marginBottom: 12 }} />)
            ) : cycles.length > 0 ? (
              <div className="table-container">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Cycle</th>
                      <th>Target</th>
                      <th>Status</th>
                      <th>Published</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {cycles.map(c => (
                      <tr key={c.cycle_id}>
                        <td style={{ fontWeight: 600 }}>{c.header_label}</td>
                        <td style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)' }}>{c.target_key}</td>
                        <td>
                          <span className={`badge ${c.status === 'PUBLISHED' ? 'badge-success' : c.status === 'CLOSED' ? 'badge-error' : 'badge-warning'}`}>{c.status}</span>
                        </td>
                        <td style={{ fontSize: 'var(--font-size-xs)' }}>{c.published_at ? new Date(c.published_at).toLocaleDateString() : '—'}</td>
                        <td>
                          <button className="btn btn-sm btn-secondary" onClick={() => viewResults(c)}><BarChart2 size={14} /> Results</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="empty-state">
                <Users size={48} className="empty-state-icon" />
                <div className="empty-state-title">No Feedback Cycles</div>
                <div className="empty-state-text">Create your first feedback cycle to begin collecting faculty ratings</div>
              </div>
            )}
          </>
        )}

        {tab === 'results' && selectedCycle && (
          <>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 'var(--space-lg)' }}>
              <button className="btn btn-ghost btn-sm" onClick={() => setTab('cycles')}>← Back</button>
              <h3 style={{ margin: 0 }}>{selectedCycle.header_label} — Results</h3>
            </div>
            {summaryLoading ? (
              [1,2].map(i => <div key={i} className="skeleton" style={{ height: 80, marginBottom: 12 }} />)
            ) : entrySummary.length > 0 ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
                {entrySummary.map(entry => (
                  <div key={entry.entry_id} className="card">
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 'var(--space-sm)' }}>
                      <div>
                        <div style={{ fontWeight: 700 }}>{entry.teacher_name}</div>
                        <div style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)' }}>{entry.subject_label}</div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontWeight: 700, fontSize: 'var(--font-size-lg)', color: 'var(--color-accent)' }}>{parseFloat(entry.avg_rating || 0).toFixed(2)}</div>
                        <div style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)' }}>avg · {entry.response_count} responses</div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="empty-state">
                <BarChart2 size={48} className="empty-state-icon" />
                <div className="empty-state-title">No Results Yet</div>
                <div className="empty-state-text">No student responses submitted yet for this cycle</div>
              </div>
            )}
          </>
        )}

        {tab === 'appeals' && (
          <Link href="/admin/appeals" className="card card-interactive" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center', gap: 'var(--space-lg)', maxWidth: 500 }}>
            <div style={{ width: 56, height: 56, borderRadius: 'var(--radius-lg)', background: 'linear-gradient(135deg, #43e97b, #38f9d7)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <AlertCircle size={26} color="white" />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700, fontSize: 'var(--font-size-lg)' }}>Profile Appeals</div>
              <div style={{ fontSize: 'var(--font-size-sm)', color: 'var(--color-text-muted)' }}>Students requesting profile edit access</div>
            </div>
            <ChevronRight size={20} color="var(--color-text-muted)" />
          </Link>
        )}
      </div>
    </>
  );
}
import React from 'react';

export default function AdminFeedbackPage() {
  return <div className="p-6">Admin Feedback (placeholder)</div>;
}
