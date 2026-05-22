"use client";

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Lock, LogOut, RefreshCw } from 'lucide-react';
import { useAuth } from '../../providers/AuthProvider';

export default function LockedAccountPage() {
  const { logout, user, identity, loading, refreshProfile, authDataError } = useAuth();
  const [retryError, setRetryError] = useState('');
  const [retrying, setRetrying] = useState(false);
  const router = useRouter();

  useEffect(() => {
    if (!loading && identity) {
      const dest = identity.account_type === 'ADMIN' ? '/admin' : '/dashboard';
      router.replace(dest);
    }
  }, [loading, identity, router]);

  const retry = async () => {
    setRetryError('');
    setRetrying(true);
    try {
      const refreshed = await refreshProfile();
      if (refreshed?.identity?.account_type === 'ADMIN') {
        router.replace('/admin');
      } else if (refreshed?.identity?.account_type === 'STUDENT') {
        router.replace('/dashboard');
      } else {
        setRetryError('No active identity mapping was returned for this signed-in account.');
      }
    } catch (error: any) {
      setRetryError(error?.message || 'Retry failed. Please check the Supabase identity mapping.');
    } finally {
      setRetrying(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'var(--color-bg-primary)', padding: 'var(--space-lg)'
    }}>
      <div className="card animate-fade-in-up" style={{ maxWidth: 480, textAlign: 'center', padding: 'var(--space-3xl) var(--space-xl)' }}>
        <div style={{
          width: 80, height: 80, borderRadius: 'var(--radius-full)',
          background: 'rgba(239, 68, 68, 0.15)', display: 'flex',
          alignItems: 'center', justifyContent: 'center', margin: '0 auto var(--space-lg)'
        }}>
          <Lock size={40} color="var(--color-error)" />
        </div>

        <h1 style={{ fontSize: 'var(--font-size-2xl)', fontWeight: 800, marginBottom: 'var(--space-sm)' }}>
          Account Locked
        </h1>

        <p style={{ color: 'var(--color-text-muted)', fontSize: 'var(--font-size-base)', lineHeight: 1.7, marginBottom: 'var(--space-xl)' }}>
          We could not find an active identity mapping for your account. If your admin has just repaired the account, retry once. Otherwise sign out and use one of the mapped GEHU Connect accounts.
        </p>

        {(authDataError || retryError) && (
          <p style={{ color: 'var(--color-error)', fontSize: 'var(--font-size-sm)', marginBottom: 'var(--space-md)' }}>
            {retryError || authDataError}
          </p>
        )}

        {user?.email && (
          <div className="chip" style={{ justifyContent: 'center', margin: '0 auto var(--space-md)', width: 'fit-content' }}>
            {user.email}
          </div>
        )}

        <div style={{ display: 'flex', justifyContent: 'center', gap: 10, flexWrap: 'wrap' }}>
          <button className="btn btn-primary" onClick={retry} disabled={retrying} style={{ gap: 8 }}>
            <RefreshCw size={18} /> {retrying ? 'Retrying...' : 'Retry Mapping'}
          </button>
          <button className="btn btn-secondary" onClick={logout} style={{ gap: 8 }}>
            <LogOut size={18} /> Sign Out
          </button>
        </div>
      </div>
    </div>
  );
}
