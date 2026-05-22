"use client";

import React from 'react';
import { CheckCircle, Clock, LogOut } from 'lucide-react';
import { useAuth } from '../../providers/AuthProvider';

export default function PendingVerificationPage() {
  const { logout, user } = useAuth();

  return (
    <div style={{
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'var(--color-bg-primary)', padding: 'var(--space-lg)'
    }}>
      <div className="card animate-fade-in-up" style={{ maxWidth: 480, textAlign: 'center', padding: 'var(--space-3xl) var(--space-xl)' }}>
        <div style={{
          width: 80, height: 80, borderRadius: 'var(--radius-full)',
          background: 'rgba(245, 158, 11, 0.15)', display: 'flex',
          alignItems: 'center', justifyContent: 'center', margin: '0 auto var(--space-lg)'
        }}>
          <Clock size={40} color="var(--color-warning)" />
        </div>

        <h1 style={{ fontSize: 'var(--font-size-2xl)', fontWeight: 800, marginBottom: 'var(--space-sm)' }}>
          Verification Pending
        </h1>

        <p style={{ color: 'var(--color-text-muted)', fontSize: 'var(--font-size-base)', lineHeight: 1.7, marginBottom: 'var(--space-xl)' }}>
          Your profile has been submitted successfully. An administrator will review and verify your details.
          You'll be able to access the platform once your profile is approved.
        </p>

        <div style={{
          background: 'var(--color-bg-elevated)', borderRadius: 'var(--radius-md)',
          padding: 'var(--space-md)', marginBottom: 'var(--space-xl)',
          display: 'flex', alignItems: 'center', gap: 'var(--space-sm)'
        }}>
          <CheckCircle size={18} color="var(--color-success)" />
          <span style={{ fontSize: 'var(--font-size-sm)', color: 'var(--color-text-secondary)' }}>
            Submitted as: <strong>{user?.email}</strong>
          </span>
        </div>

        <button className="btn btn-secondary" onClick={logout} style={{ gap: 8 }}>
          <LogOut size={18} /> Sign Out
        </button>
      </div>
    </div>
  );
}
