"use client";

import React, { useState } from 'react';
import { supabase } from '../../../utils/supabaseClient';
import { Send, Bell, Users, AlertCircle, CheckCircle } from 'lucide-react';

export default function AdminBroadcastPage() {
  const [form, setForm] = useState({ title: '', message: '', targetType: 'ALL', course: '', semester: '' });
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<any>(null);

  const set = (k: string, v: any) => setForm((p: any) => ({ ...p, [k]: v }));

  const send = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim() || !form.message.trim()) {
      setResult({ ok: false, msg: 'Title and message are required.' });
      return;
    }
    setSending(true);
    setResult(null);
    try {
      const payload = {
        type: 'BROADCAST',
        title: form.title.trim(),
        message: form.message.trim(),
        target_type: form.targetType,
        target_key: form.targetType === 'ALL'
          ? 'all_students'
          : [form.course, form.semester].filter(Boolean).join('_').toLowerCase() || 'all_students',
        priority: 'NORMAL',
        is_read: false,
        created_at: new Date().toISOString(),
      };

      const { error } = await supabase.from('app_notifications').insert(payload);
      if (error) throw error;
      setResult({ ok: true, msg: 'Broadcast sent successfully to ' + (form.targetType === 'ALL' ? 'all students' : `${form.course || ''} ${form.semester ? 'Sem ' + form.semester : ''}`.trim()) + '.' });
      setForm({ title: '', message: '', targetType: 'ALL', course: '', semester: '' });
    } catch (err: any) {
      setResult({ ok: false, msg: 'Error: ' + (err?.message || String(err)) });
    } finally {
      setSending(false);
    }
  };

  return (
    <>
      <div className="page-header">
        <div>
          <div className="page-title">Broadcast Notification</div>
          <div className="page-subtitle">Send announcements to all or targeted students</div>
        </div>
      </div>
      <div className="page-body animate-fade-in-up" style={{ maxWidth: 640 }}>
        <form onSubmit={send}>
          <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-lg)' }}>
            <div>
              <div style={{ fontWeight: 700, marginBottom: 'var(--space-md)', display: 'flex', alignItems: 'center', gap: 8 }}>
                <Users size={18} color="var(--color-accent)" /> Audience
              </div>
              <div style={{ display: 'flex', gap: 'var(--space-md)', flexWrap: 'wrap' }}>
                {['ALL', 'SEGMENT'].map(t => (
                  <label key={t} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 18px', borderRadius: 'var(--radius-md)', border: `2px solid ${form.targetType === t ? 'var(--color-accent)' : 'var(--color-border)'}`, background: form.targetType === t ? 'var(--color-accent-subtle)' : 'transparent', cursor: 'pointer', transition: 'all 0.2s' }}>
                    <input type="radio" name="targetType" value={t} checked={form.targetType === t} onChange={() => set('targetType', t)} style={{ display: 'none' }} />
                    <span style={{ fontWeight: 600, color: form.targetType === t ? 'var(--color-accent)' : 'var(--color-text-muted)', fontSize: 'var(--font-size-sm)' }}>
                      {t === 'ALL' ? '🌐 All Students' : '🎯 Specific Group'}
                    </span>
                  </label>
                ))}
              </div>

              {form.targetType === 'SEGMENT' && (
                <div style={{ display: 'flex', gap: 'var(--space-md)', marginTop: 'var(--space-md)' }}>
                  <div className="input-group" style={{ flex: 1 }}>
                    <label className="input-label">Course (e.g. MCA)</label>
                    <input className="input" type="text" value={form.course} onChange={e => set('course', e.target.value)} placeholder="MCA, BCA..." />
                  </div>
                  <div className="input-group" style={{ flex: 1 }}>
                    <label className="input-label">Semester (optional)</label>
                    <input className="input" type="number" min="1" max="8" value={form.semester} onChange={e => set('semester', e.target.value)} placeholder="1–8" />
                  </div>
                </div>
              )}
            </div>

            <div>
              <div style={{ fontWeight: 700, marginBottom: 'var(--space-md)', display: 'flex', alignItems: 'center', gap: 8 }}>
                <Bell size={18} color="var(--color-accent)" /> Notification Content
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
                <div className="input-group">
                  <label className="input-label">Title</label>
                  <input className="input" type="text" value={form.title} onChange={e => set('title', e.target.value)} placeholder="e.g. Campus Closure Notice" maxLength={120} />
                </div>
                <div className="input-group">
                  <label className="input-label">Message</label>
                  <textarea className="input" rows={5} value={form.message} onChange={e => set('message', e.target.value)} placeholder="Enter the full notification message..." maxLength={1000} style={{ resize: 'vertical' }} />
                  <div style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)', textAlign: 'right', marginTop: 4 }}>{form.message.length}/1000</div>
                </div>
              </div>
            </div>

            {result && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 16px', borderRadius: 'var(--radius-md)', background: result.ok ? 'rgba(16,185,129,0.1)' : 'rgba(239,68,68,0.1)', color: result.ok ? '#10b981' : '#ef4444', fontWeight: 500, fontSize: 'var(--font-size-sm)' }}>
                {result.ok ? <CheckCircle size={18} /> : <AlertCircle size={18} />}
                {result.msg}
              </div>
            )}

            <button type="submit" className="btn btn-primary" disabled={sending} style={{ width: '100%', justifyContent: 'center', padding: '14px' }}>
              <Send size={18} /> {sending ? 'Sending...' : 'Send Broadcast'}
            </button>
          </div>
        </form>
      </div>
    </>
  );
}

