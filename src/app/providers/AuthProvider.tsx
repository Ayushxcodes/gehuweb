
"use client";

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { supabase } from '../../utils/supabaseClient';
import { Roles } from '../../utils/constants';

const AuthContext = createContext<any>(null);
const LOOKUP_TIMEOUT_MS = 30000;
const RPC_SNAPSHOT_TIMEOUT_MS = 30000;
const SIGN_IN_TIMEOUT_MS = 15000;

function withTimeout<T>(promise: Promise<T>, timeoutMs: number, label = 'operation') {
  let timeoutId: any;
  const timeout = new Promise<never>((_, reject) => {
    timeoutId = setTimeout(() => {
      reject(new Error(`${label} timed out. Please retry.`));
    }, timeoutMs);
  });

  return Promise.race([promise, timeout]).finally(() => clearTimeout(timeoutId));
}

async function retryWithBackoff(fn: () => Promise<any>, attempts = 3, baseDelay = 500) {
  let lastErr: any;
  for (let i = 0; i < attempts; i++) {
    try {
      const res = await fn();
      if (res && res.error) throw res.error;
      return res;
    } catch (e) {
      lastErr = e;
      if (i < attempts - 1) await new Promise((r) => setTimeout(r, baseDelay * Math.pow(2, i)));
    }
  }
  throw lastErr;
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<any>(null);
  const [identity, setIdentity] = useState<any>(null);
  const [profileState, setProfileState] = useState<any>(null);
  const [authDataError, setAuthDataError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchSessionData = useCallback(async (authSessionUser: any) => {
    if (!authSessionUser) return null;

    try {
      // Try the consolidated RPC first (faster, atomic). If it fails or is not present,
      // fall back to direct table queries.
      let rpcRes: any = null;
      try {
        const rpcStart = Date.now();
        rpcRes = await retryWithBackoff(() => withTimeout(
          // @ts-ignore
          supabase.rpc('api_auth_route_snapshot', { p_auth_user_id: authSessionUser.id }).maybeSingle(),
          RPC_SNAPSHOT_TIMEOUT_MS,
          'Route snapshot'
        ), 3, 500);
        const rpcDur = Date.now() - rpcStart;
        console.debug('[Auth] RPC snapshot succeeded in', rpcDur, 'ms');
      } catch (e) {
        console.warn('[Auth] RPC snapshot unavailable or timed out (ms):', Date.now() - (typeof rpcStart !== 'undefined' ? rpcStart : 0), e?.message || e);
      }

      let identityData: any = null;
      let pState: any = null;

      if (rpcRes && rpcRes.data) {
        const row = rpcRes.data;
        identityData = {
          auth_user_id: row.auth_user_id,
          account_type: row.account_type,
          student_id: row.student_id,
          employee_id: row.employee_id,
          is_active: row.is_active,
          email: row.email || authSessionUser.email || null,
        };

        pState = {
          uid: row.uid,
          name: row.name,
          official_email: row.official_email,
          student_id_label: row.student_id_label,
          roll_no: row.roll_no,
          course: row.course,
          branch: row.branch,
          semester: row.semester,
          profile_completed: row.profile_completed,
          verification_status: row.verification_status,
          verified: row.verified,
          edit_unlocked_until: row.edit_unlocked_until,
        };
        setAuthDataError(null);
      } else {
        // Identity lookup with retry
        let idRes: any;
        try {
          const idStart = Date.now();
          idRes = await retryWithBackoff(() => withTimeout(
            // @ts-ignore
            supabase
              .from('app_user_identity')
              .select('auth_user_id,account_type,student_id,employee_id,is_active')
              .eq('auth_user_id', authSessionUser.id)
              .eq('is_active', true)
              .maybeSingle(),
            LOOKUP_TIMEOUT_MS,
            'Identity lookup'
          ), 3, 500);
          console.debug('[Auth] Identity lookup succeeded in', Date.now() - idStart, 'ms');
        } catch (e) {
          console.error('[Auth] Identity lookup failed or timed out after', LOOKUP_TIMEOUT_MS, 'ms:', e);
          throw new Error(e.message || 'Identity lookup failed');
        }

        identityData = idRes?.data
          ? { ...idRes.data, email: authSessionUser.email || null }
          : null;

        if (identityData) {
          // Profile state lookup with retry; only set authDataError after retries exhausted
          let pRes: any;
          try {
            const pStart = Date.now();
            pRes = await retryWithBackoff(() => withTimeout(
              // @ts-ignore
              supabase
                .from('app_profile_state')
                .select('uid,name,official_email,student_id_label,roll_no,course,branch,semester,profile_completed,verification_status,verified,edit_unlocked_until')
                .eq('auth_user_id', authSessionUser.id)
                .maybeSingle(),
              LOOKUP_TIMEOUT_MS,
              'Profile state lookup'
            ), 3, 500);
            console.debug('[Auth] Profile state lookup succeeded in', Date.now() - pStart, 'ms');
          } catch (e) {
            console.error('[Auth] Profile state fetch error (ms):', Date.now() - (typeof pStart !== 'undefined' ? pStart : 0), e);
            setAuthDataError(`Profile state lookup failed: ${e.message || e.code || 'unknown error'}`);
            pState = identityData.account_type === Roles.ADMIN
              ? {
                  profile_completed: true,
                  verification_status: 'VERIFIED',
                  verified: true,
                }
              : null;
          }

          if (pRes) {
            if (pRes.error) {
              console.error('Profile state fetch error:', pRes.error);
              setAuthDataError(`Profile state lookup failed: ${pRes.error.message || pRes.error.code || 'unknown error'}`);
              pState = identityData.account_type === Roles.ADMIN
                ? {
                    profile_completed: true,
                    verification_status: 'VERIFIED',
                    verified: true,
                  }
                : null;
            } else {
              setAuthDataError(null);
              pState = pRes.data || {
                profile_completed: identityData.account_type === Roles.ADMIN,
                verification_status: identityData.account_type === Roles.ADMIN ? 'VERIFIED' : 'PENDING',
                verified: identityData.account_type === Roles.ADMIN,
              };
              identityData = {
                ...identityData,
                uid: pState.uid || identityData.auth_user_id,
                name: pState.name || null,
                official_email: pState.official_email || authSessionUser.email || null,
                student_id_label: pState.student_id_label || null,
                roll_no: pState.roll_no || null,
                course: pState.course || null,
                branch: pState.branch || null,
                semester: pState.semester ?? null,
              };
            }
          }
        } else {
          setAuthDataError(null);
        }
      }

      const merged = {
        ...authSessionUser,
        identity: identityData,
        profileState: pState,
      };

      setIdentity(identityData);
      setProfileState(pState);
      return merged;
    } catch (error: any) {
      console.error('Auth session data fetch failed:', error);
      setAuthDataError(error.message || 'Auth route lookup failed.');
      // Do NOT nullify identity/profile here. If this is a background sync failure,
      // we want to preserve the existing state so the user isn't kicked offline.
      return null;
    }
  }, []);

  useEffect(() => {
    let active = true;

    const loadInitialSession = async () => {
      try {
        const { data, error } = await withTimeout(
          supabase.auth.getSession(),
          LOOKUP_TIMEOUT_MS,
          'Session lookup'
        );

        if (error) throw error;
        if (!active) return;

        const sessionUser = data?.session?.user;
        if (sessionUser) {
          const userData = await fetchSessionData(sessionUser);
          if (active && userData) {
            setUser(userData);
          } else if (active && !userData) {
            // If we failed to fetch data on initial load, we can't log them in safely
            setUser(null);
            setIdentity(null);
            setProfileState(null);
          }
        } else {
          setUser(null);
          setIdentity(null);
          setProfileState(null);
          setAuthDataError(null);
        }
      } catch (error: any) {
        console.error('Error getting session:', error);
        if (active) {
          setUser(null);
          setIdentity(null);
          setProfileState(null);
          setAuthDataError(error.message || 'Session lookup failed.');
        }
      } finally {
        if (active) setLoading(false);
      }
    };

    loadInitialSession();

    const hardStop = setTimeout(() => {
      if (active) {
        console.warn('AuthContext safety timeout reached');
        setLoading(false);
      }
    }, LOOKUP_TIMEOUT_MS * 2 + 5000);

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event: any, session: any) => {
        try {
          if (session?.user) {
            const userData = await fetchSessionData(session.user);
            // ONLY update user if the background sync succeeded.
            // If it failed (userData is null), DO NOTHING. Let the user stay logged in.
            if (active && userData) setUser(userData);
          } else {
            setUser(null);
            setIdentity(null);
            setProfileState(null);
            setAuthDataError(null);
          }
        } catch (error) {
          console.error('Auth state refresh failed:', error);
        } finally {
          if (active) setLoading(false);
        }
      }
    );

    return () => {
      active = false;
      clearTimeout(hardStop);
      subscription?.unsubscribe();
    };
  }, [fetchSessionData]);

  // Proactive keep-alive & wake-from-sleep resiliency
  useEffect(() => {
    const checkAndRefresh = async () => {
      try {
        const { data, error } = await supabase.auth.getSession();
        if (error || !data?.session) return;
        const expiresAt = data.session.expires_at; // Unix seconds
        const now = Math.floor(Date.now() / 1000);
        if (expiresAt - now < 600) { // Less than 10 min remaining or already expired
          console.log('[AuthKeepAlive] Token expiring or expired, refreshing...');
          await supabase.auth.refreshSession();
        }
      } catch (e) {
        console.warn('[AuthKeepAlive] Refresh error:', e);
      }
    };

    // 1. Silent interval check every 5 minutes
    const keepAlive = setInterval(checkAndRefresh, 5 * 60 * 1000);

    // 2. Immediate check on wake from sleep (visibility change)
    const handleVisibility = () => {
      if (document.visibilityState === 'visible') {
        console.log('[AuthKeepAlive] Tab activated, pre-checking session freshness...');
        checkAndRefresh();
      }
    };

    document.addEventListener('visibilitychange', handleVisibility);

    return () => {
      clearInterval(keepAlive);
      document.removeEventListener('visibilitychange', handleVisibility);
    };
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const maskedEmail = typeof email === 'string'
      ? `${String(email).split('@')[0].slice(0, 3)}***@${String(email).split('@')[1] || ''}`
      : 'unknown';
    console.debug('[Auth.login] start', { email: maskedEmail });
    const start = Date.now();
    try {
      const res = await withTimeout(
        supabase.auth.signInWithPassword({ email, password }),
        SIGN_IN_TIMEOUT_MS,
        'Supabase sign in'
      );
      const duration = Date.now() - start;
      console.debug('[Auth.login] signInWithPassword returned', { duration, res });

      const { data, error } = res as any;
      if (error) {
        console.error('[Auth.login] sign-in error', { error });
        throw error;
      }

      const mergedUser = data?.user ? await fetchSessionData(data.user) : null;
      if (mergedUser) {
        setUser(mergedUser);
        console.debug('[Auth.login] merged user set', { uid: mergedUser.id || mergedUser.user?.id });
      } else {
        console.debug('[Auth.login] no merged user, using raw user', { uid: data?.user?.id });
      }

      return {
        ...data,
        user: mergedUser || data?.user || null,
      };
    } catch (e: any) {
      // Safely extract error details for non-Error throws (network responses, plain objects, strings)
      const errorType = e && e.constructor ? e.constructor.name : typeof e;
      const message = e?.message || (typeof e === 'string' ? e : undefined);
      let serialized: string | null = null;
      try {
        if (e && typeof e === 'object') serialized = JSON.stringify(e, Object.getOwnPropertyNames(e));
      } catch (serErr) {
        try { serialized = String(e); } catch { serialized = null; }
      }

      console.error('[Auth.login] failed', {
        errorType,
        message: message || serialized || String(e),
        stack: e?.stack,
        raw: e,
      });

      throw e;
    }
  }, [fetchSessionData]);

  const register = useCallback(async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) throw error;
    return data;
  }, []);

  const logout = useCallback(async () => {
    try {
      await withTimeout(supabase.auth.signOut(), 5000, 'Logout');
    } catch (e) {
      console.warn('Logout network call timed out, forcing local logout.');
    }
    setUser(null);
    setIdentity(null);
    setProfileState(null);
    setAuthDataError(null);
  }, []);

  const refreshProfile = useCallback(async () => {
    const { data, error } = await withTimeout(
      supabase.auth.getSession(),
      LOOKUP_TIMEOUT_MS,
      'Session refresh'
    );

    if (error) throw error;

    const sessionUser = data?.session?.user;
    if (sessionUser) {
      const userData = await fetchSessionData(sessionUser);
      setUser(userData);
      return userData;
    }

    return null;
  }, [fetchSessionData]);

  const accountType = identity?.account_type || Roles.STUDENT;
  const isAdmin = accountType === Roles.ADMIN;
  const isStudent = accountType === Roles.STUDENT;
  const isCoordinator = accountType === Roles.COORDINATOR;
  const isAuthenticated = !!user;

  const profileCompleted = !!profileState?.profile_completed;
  const isPendingVerification = profileState?.verification_status === 'PENDING' && profileCompleted;

  const value = {
    user,
    identity,
    profileState,
    authDataError,
    setUser,
    loading,
    login,
    register,
    logout,
    refreshProfile,
    isAdmin,
    isStudent,
    isCoordinator,
    isAuthenticated,
    profileCompleted,
    isPendingVerification,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}

export default AuthProvider;
