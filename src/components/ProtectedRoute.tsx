"use client";

import React from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAuth } from '../app/providers/AuthProvider';

type Props = {
  children: React.ReactNode;
  requiredRole?: string | null;
  requireProfileComplete?: boolean;
};

export default function ProtectedRoute({ children, requiredRole = null }: Props) {
  const {
    isAuthenticated,
    loading,
    isAdmin,
    identity,
    profileCompleted,
    isPendingVerification,
    authDataError,
    refreshProfile,
  } = useAuth();

  const router = useRouter();
  const pathname = usePathname();

  React.useEffect(() => {
    if (loading) return;

    if (!isAuthenticated) {
      router.replace(`/auth/login?from=${encodeURIComponent(pathname || '/')}`);
      return;
    }

    if (!identity && pathname !== '/locked') {
      router.replace('/locked');
      return;
    }

    if (!profileCompleted && pathname !== '/profile-setup') {
      router.replace('/profile-setup');
      return;
    }

    if (isPendingVerification && pathname !== '/pending-verification' && pathname !== '/profile-setup') {
      router.replace('/pending-verification');
      return;
    }

    if (requiredRole === 'ADMIN' && !isAdmin) {
      router.replace('/dashboard');
      return;
    }
  }, [loading, isAuthenticated, identity, profileCompleted, isPendingVerification, isAdmin, pathname, requiredRole, router]);

  if (loading) {
    return (
      <div className="loading-overlay">
        <div className="loading-screen">
          <div className="spinner" style={{ width: 40, height: 40 }}></div>
          <p>Loading...</p>
        </div>
      </div>
    );
  }

  if (identity && authDataError) {
    return (
      <div className="loading-overlay">
        <div className="card" style={{ maxWidth: 520, padding: '2rem', textAlign: 'center' }}>
          <h2 style={{ marginBottom: '0.5rem' }}>Profile Route Check Failed</h2>
          <p style={{ color: '#6b7280', lineHeight: 1.6 }}>
            Your login identity was found, but the profile state could not be verified safely. We are not sending you
            to setup or locked screens because that could corrupt the route decision.
          </p>
          <p style={{ color: '#dc2626', fontSize: '0.875rem', marginTop: '1rem' }}>{authDataError}</p>
          <button className="btn btn-primary" style={{ marginTop: '1rem' }} onClick={refreshProfile}>
            Retry Profile Check
          </button>
        </div>
      </div>
    );
  }

  // If we reached here, render children — any redirects have been triggered by effect.
  return <>{children}</>;
}
