import React from 'react';
import { Wrench } from 'lucide-react';

type Props = {
  title?: string;
  message?: string;
};

export default function ComingSoon({ title = 'Coming Soon', message = 'This module is currently being migrated to Supabase native architecture. Check back soon!' }: Props) {
  return (
    <>
      <div className="page-header">
        <div>
          <div className="page-title">{title}</div>
          <div className="page-subtitle">Maintenance in progress</div>
        </div>
      </div>
      <div className="page-body animate-fade-in-up" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '60vh' }}>
        <div className="empty-state" style={{ maxWidth: 500, margin: '0 auto', background: 'rgba(255,255,255,0.02)', backdropFilter: 'blur(10px)', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-xl)', padding: '2rem' }}>
          <div style={{ width: 80, height: 80, borderRadius: '50%', background: 'rgba(34, 211, 238, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '1rem', border: '1px solid rgba(34, 211, 238, 0.3)' }}>
            <Wrench size={40} color="var(--color-accent)" />
          </div>
          <div style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.75rem', color: 'var(--color-text-primary)' }}>Supabase Migration</div>
          <div style={{ fontSize: '1rem', color: 'var(--color-text-muted)', lineHeight: 1.6 }}>{message}</div>
        </div>
      </div>
    </>
  );
}
