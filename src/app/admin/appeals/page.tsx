"use client";

import React, { useState, useEffect } from 'react';
import { supabase } from '../../../utils/supabaseClient';
import { FileQuestion, CheckCircle, XCircle, AlertCircle, RefreshCw } from 'lucide-react';
import { useAuth } from '../../providers/AuthProvider';

export default function AdminAppealsPage() {
  const { identity } = useAuth();
  const [appeals, setAppeals] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState('');

  const fetchAppeals = async () => {
    setLoading(true);
    setErrorMsg('');
    try {
      const { data, error } = await supabase
        .from('app_appeals')
        .select('*')
        .order('source_created_at', { ascending: false });

      if (error) throw error;
      setAppeals(data || []);
    } catch (err: any) {
      console.error('Error fetching appeals:', err);
      setErrorMsg(err?.message || 'Failed to load appeals.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAppeals();
  }, []);

  const handleAction = async (appeal: any, newStatus: string) => {
    setProcessing(appeal.appeal_id);
    setErrorMsg('');
    try {
      const { error: updateError } = await supabase
        .from('app_appeals')
        .update({
          status: newStatus,
          admin_note: `Appeal ${newStatus.toLowerCase()} by Admin`,
          resolved_at: new Date().toISOString(),
          resolved_by_auth_user_id: identity?.auth_user_id || null,
        })
        .eq('appeal_id', appeal.appeal_id);

      if (updateError) throw updateError;

      if (newStatus === 'RESOLVED') {
        const unlockUntil = new Date();
        unlockUntil.setHours(unlockUntil.getHours() + 48);
        const isVerificationAppeal = appeal.type === 'PROFILE_VERIFICATION';

        const { error: profileError } = await supabase
          .from('app_profile_state')
          .update(
            isVerificationAppeal
              ? {
                  verified: true,
                  verification_status: 'VERIFIED',
                  edit_unlocked_until: null,
                }
              : {
                  verified: true,
                  verification_status: 'VERIFIED',
                  edit_unlocked_until: unlockUntil.toISOString(),
                }
          )
          .eq('uid', appeal.uid);

        if (profileError) throw profileError;
      }

      await fetchAppeals();
    } catch (err: any) {
      console.error('Error resolving appeal:', err);
      setErrorMsg(err?.message || 'Failed to update appeal.');
    } finally {
      setProcessing(null);
    }
  };

  return (
    <>
      <div className="page-header">
        <div>
          <div className="page-title">Profile Appeals</div>
          <div className="page-subtitle">Review student change requests</div>
        </div>
        <button className="btn btn-secondary" onClick={fetchAppeals} disabled={loading}>
          <RefreshCw size={16} className={loading ? 'spin' : ''} /> Refresh
        </button>
      </div>

      <div className="page-body animate-fade-in-up">
        {errorMsg && (
          <div className="card" style={{ color: 'var(--color-error)', marginBottom: 'var(--space-md)' }}>
            <AlertCircle size={18} /> {errorMsg}
          </div>
        )}
        {loading && appeals.length === 0 ? (
          <div style={{ padding: '2rem', textAlign: 'center' }}>Loading appeals...</div>
        ) : appeals.length === 0 ? (
          <div className="card" style={{ textAlign: 'center', padding: '3rem 1rem' }}>
            <CheckCircle size={40} color="var(--color-success)" style={{ margin: '0 auto 1rem' }} />
            <div style={{ fontWeight: 600 }}>No Pending Appeals</div>
            <div style={{ color: 'var(--color-text-muted)' }}>You are all caught up!</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
            {appeals.map((a) => (
              <div
                key={a.appeal_id}
                className="card"
                style={{
                  borderLeft: a.status === 'PENDING' ? '4px solid var(--color-warning)' : '4px solid var(--color-border)',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: 'var(--font-size-lg)' }}>{a.name}</div>
                    <div style={{ color: 'var(--color-text-muted)', fontSize: 'var(--font-size-sm)' }}>
                      {a.email} • Roll: {a.roll_no} • {a.course} ({a.semester} Sem)
                    </div>
                  </div>
                  <div
                    style={{
                      padding: '4px 8px',
                      borderRadius: 'var(--radius-full)',
                      fontSize: '12px',
                      fontWeight: 600,
                      background:
                        a.status === 'PENDING'
                          ? 'var(--color-warning-light)'
                          : a.status === 'RESOLVED'
                          ? 'var(--color-success-light)'
                          : 'var(--color-error-light)',
                      color:
                        a.status === 'PENDING'
                          ? 'var(--color-warning-dark)'
                          : a.status === 'RESOLVED'
                          ? 'var(--color-success-dark)'
                          : 'var(--color-error-dark)',
                    }}
                  >
                    {a.status}
                  </div>
                </div>

                <div style={{ background: 'var(--color-bg-elevated)', padding: 'var(--space-md)', borderRadius: 'var(--radius-md)', marginTop: 'var(--space-md)' }}>
                  <div style={{ fontSize: '12px', fontWeight: 600, color: 'var(--color-text-muted)', marginBottom: 4 }}>STUDENT MESSAGE</div>
                  <div style={{ marginBottom: 'var(--space-md)' }}>{a.message}</div>

                  <div style={{ fontSize: '12px', fontWeight: 600, color: 'var(--color-text-muted)', marginBottom: 4 }}>REQUESTED CHANGES (JSON)</div>
                  <pre style={{ margin: 0, fontSize: '13px', whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
                    {JSON.stringify(a.profile_data_json?.requested_changes, null, 2)}
                  </pre>
                </div>

                {a.status === 'PENDING' && (
                  <div style={{ display: 'flex', gap: 'var(--space-sm)', marginTop: 'var(--space-md)', justifyContent: 'flex-end' }}>
                    <button className="btn btn-secondary" onClick={() => handleAction(a, 'REJECTED')} disabled={processing === a.appeal_id}>
                      <XCircle size={16} /> Reject
                    </button>
                    <button className="btn btn-primary" onClick={() => handleAction(a, 'RESOLVED')} disabled={processing === a.appeal_id}>
                      <CheckCircle size={16} /> {a.type === 'PROFILE_VERIFICATION' ? 'Verify Profile' : 'Approve & Unlock'}
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
