"use client";

import React from 'react';
import { Settings as SettingsIcon, User, Shield, Moon } from 'lucide-react';
import { useAuth } from '../providers/AuthProvider';

export default function SettingsPage() {
  const { user } = useAuth();
  return (
    <>
      <div className="page-header"><div><div className="page-title">Settings</div><div className="page-subtitle">Account and preferences</div></div></div>
      <div className="page-body animate-fade-in-up" style={{ maxWidth: 600 }}>
        <div className="card" style={{ marginBottom: 'var(--space-lg)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-lg)' }}>
            <div className="avatar avatar-xl">{user?.name?.[0]?.toUpperCase() || '?'}</div>
            <div>
              <div style={{ fontWeight: 700, fontSize: 'var(--font-size-xl)' }}>{user?.name || 'User'}</div>
              <div style={{ color: 'var(--color-text-muted)' }}>{user?.email}</div>
              <div style={{ marginTop: 4 }}><span className="badge badge-accent">{user?.role}</span></div>
            </div>
          </div>
        </div>
        <div className="card" style={{ marginBottom: 'var(--space-lg)' }}>
          <h3 style={{ marginBottom: 'var(--space-md)' }}>Profile Details</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '120px 1fr', gap: 'var(--space-sm)', fontSize: 'var(--font-size-sm)', color: 'var(--color-text-secondary)' }}>
            <span style={{ color: 'var(--color-text-muted)' }}>Course</span><span>{user?.course || '—'}</span>
            <span style={{ color: 'var(--color-text-muted)' }}>Branch</span><span>{user?.branch || '—'}</span>
            <span style={{ color: 'var(--color-text-muted)' }}>Semester</span><span>{user?.semester || '—'}</span>
            <span style={{ color: 'var(--color-text-muted)' }}>Roll No</span><span>{user?.roll_no || '—'}</span>
            <span style={{ color: 'var(--color-text-muted)' }}>Phone</span><span>{user?.phone || '—'}</span>
          </div>
        </div>
      </div>
    </>
  );
}
