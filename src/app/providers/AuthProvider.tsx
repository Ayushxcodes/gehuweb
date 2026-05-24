"use client";

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../utils/supabaseClient';
import { Roles } from '../../utils/constants';

const AuthContext = createContext<any>(null);
const LOOKUP_TIMEOUT_MS = 12000;
const RPC_SNAPSHOT_TIMEOUT_MS = 10000;
const SIGN_IN_TIMEOUT_MS = 45000;
const LOGIN_ROUTE_LOOKUP_GRACE_MS = 4500;

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

function guessAccountTypeFromEmail(email?: string | null) {
  return String(email || '').toLowerCase().includes('admin') ? Roles.ADMIN : Roles.STUDENT;
}

function buildFallbackSignedInUser(authUser: any, emailHint?: string | null) {
  const accountType = guessAccountTypeFromEmail(authUser?.email || emailHint);
  const identity = {
    auth_user_id: authUser?.id || null,
    account_type: accountType,
    student_id: null,
    employee_id: null,
    is_active: true,
    email: authUser?.email || emailHint || null,
  };
  const profileState = accountType === Roles.ADMIN
    ? {
        profile_completed: true,
        verification_status: 'VERIFIED',
        verified: true,
      }
    : null;

  return {
    identity,
    profileState,
    user: {
      ...authUser,
      identity,
      profileState,
    },
  };
}

function describeAuthError(error: any) {
  if (!error || typeof error !== 'object') {
    return { message: String(error || 'Unknown auth error') };
  }
  return {
    name: error.name,
    status: error.status,
    code: error.code,
    message: error.message || String(error),
    details: error.details,
    hint: error.hint,
  };
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const queryClient = useQueryClient();
  const [user, setUser] = useState<any>(null);
  const [identity, setIdentity] = useState<any>(null);
  const [profileState, setProfileState] = useState<any>(null);
  const [authDataError, setAuthDataError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Keep track of pending user for session sync if offline or sleeping
  const pendingSyncUser = React.useRef<any>(null);
  const loginHydrationRun = React.useRef(0);

  const fetchSessionData = useCallback(async (authSessionUser: any, isForeground = false) => {
    if (!authSessionUser) return null;

    // 1. Connectivity Check (Navigator.onLine)
    if (typeof window !== 'undefined' && !navigator.onLine) {
      console.debug('[AuthSync] Device is offline. Deferring identity check until network is restored.');
      pendingSyncUser.current = authSessionUser;

      const triggerOnlineSync = async () => {
        window.removeEventListener('online', triggerOnlineSync);
        if (pendingSyncUser.current) {
          console.debug('[AuthSync] Connection restored. Recovering background session.');
          const userData = await fetchSessionData(pendingSyncUser.current, false);
          if (userData) {
            setUser(userData);
          }
        }
      };
      window.addEventListener('online', triggerOnlineSync);
      return null;
    }

    try {
      // Clear pending state if online check succeeds
      pendingSyncUser.current = null;

      // Try the consolidated RPC first (faster, atomic). If it fails or is not present,
      // fall back to direct table queries.
      let rpcRes: any = null;
      let rpcStart = 0;
      try {
        rpcStart = Date.now();
        rpcRes = await retryWithBackoff(() => withTimeout(
          // @ts-ignore
          supabase.rpc('api_auth_route_snapshot').maybeSingle(),
          RPC_SNAPSHOT_TIMEOUT_MS,
          'Route snapshot'
        ), 3, 500);
        const rpcDur = Date.now() - rpcStart;
        console.debug('[AuthSync] RPC route snapshot succeeded in', rpcDur, 'ms');
      } catch (e: any) {
        if (isForeground) {
          console.warn('[AuthSync] Foreground RPC snapshot unavailable or timed out; falling back to table lookup:', e?.message || e);
        } else {
          console.debug('[AuthSync] Background RPC snapshot deferred or timed out (silent):', e?.message || e);
        }
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
          console.debug('[AuthSync] Identity lookup succeeded in', Date.now() - idStart, 'ms');
        } catch (e: any) {
          if (isForeground) {
            console.warn('[AuthSync] Foreground identity lookup failed; preserving raw auth user:', e?.message || e);
            setAuthDataError(e?.message || 'Identity lookup failed.');
            identityData = {
              auth_user_id: authSessionUser.id,
              account_type: null,
              student_id: null,
              employee_id: null,
              is_active: true,
              email: authSessionUser.email || null,
            };
            pState = null;
            const merged = {
              ...authSessionUser,
              identity: identityData,
              profileState: pState,
            };
            setIdentity(identityData);
            setProfileState(pState);
            return merged;
          } else {
            console.debug('[AuthSync] Background identity lookup timed out or failed (silent):', e?.message || e);
            return null; // Return null silently for background tasks to avoid disrupting active session
          }
        }

        identityData = idRes?.data
          ? { ...idRes.data, email: authSessionUser.email || null }
          : null;

        if (identityData) {
          // Profile state lookup with retry; only set authDataError after retries exhausted
          let pRes: any;
          let pStart = 0;
          try {
            pStart = Date.now();
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
            console.debug('[AuthSync] Profile state lookup succeeded in', Date.now() - pStart, 'ms');
          } catch (e: any) {
            if (isForeground) {
              console.warn('[AuthSync] Foreground profile state fetch error:', describeAuthError(e));
              setAuthDataError(`Profile state lookup failed: ${e.message || e.code || 'unknown error'}`);
            } else {
              console.debug('[AuthSync] Background profile state lookup timed out or failed (silent):', e?.message || e);
            }
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
              console.warn('[AuthSync] Profile state fetch error:', describeAuthError(pRes.error));
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
      if (isForeground) {
        console.warn('[AuthSync] Foreground auth session data fetch failed; preserving raw auth user:', error?.message || error);
        setAuthDataError(error.message || 'Auth route lookup failed.');
        const fallbackIdentity = {
          auth_user_id: authSessionUser.id,
          account_type: null,
          student_id: null,
          employee_id: null,
          is_active: true,
          email: authSessionUser.email || null,
        };
        const merged = {
          ...authSessionUser,
          identity: fallbackIdentity,
          profileState: null,
        };
        setIdentity(fallbackIdentity);
        setProfileState(null);
        return merged;
      } else {
        console.debug('[AuthSync] Background auth session data fetch timed out or failed (silent):', error?.message || error);
      }
      return null;
    }
  }, []);

  useEffect(() => {
    let active = true;

    const loadInitialSession = async () => {
      try {
        const { data, error } = (await withTimeout(
          supabase.auth.getSession(),
          LOOKUP_TIMEOUT_MS,
          'Session lookup'
        )) as any;

        if (error) throw error;
        if (!active) return;

        const sessionUser = data?.session?.user;
        if (sessionUser) {
          const userData = await fetchSessionData(sessionUser, false);
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
        console.warn('[AuthSync] Initial session lookup failed or timed out:', error?.message || error);
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
            const userData = await fetchSessionData(session.user, false);
            // ONLY update user if background sync succeeded.
            // If it failed (userData is null), DO NOTHING. Let the user stay logged in.
            if (active && userData) setUser(userData);
          } else {
            queryClient.clear();
            setUser(null);
            setIdentity(null);
            setProfileState(null);
            setAuthDataError(null);
          }
        } catch (error) {
          console.warn('[AuthSync] Auth state refresh failed:', describeAuthError(error));
        } finally {
          if (active) setLoading(false);
        }
      }
    );

    // Activity triggers for waking from sleep / tab focus
    const triggerSyncOnActivity = async () => {
      if (pendingSyncUser.current && typeof window !== 'undefined' && navigator.onLine) {
        console.debug('[AuthSync] Interactive user activity detected. Recovering deferred sync.');
        const userData = await fetchSessionData(pendingSyncUser.current, false);
        if (userData && active) {
          setUser(userData);
        }
      }
    };

    if (typeof window !== 'undefined') {
      window.addEventListener('mousemove', triggerSyncOnActivity, { passive: true });
      window.addEventListener('mousedown', triggerSyncOnActivity, { passive: true });
    }

    return () => {
      active = false;
      clearTimeout(hardStop);
      subscription?.unsubscribe();
      if (typeof window !== 'undefined') {
        window.removeEventListener('mousemove', triggerSyncOnActivity);
        window.removeEventListener('mousedown', triggerSyncOnActivity);
      }
    };
  }, [fetchSessionData, queryClient]);

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
        console.warn('[Auth.login] sign-in error', describeAuthError(error));
        throw error;
      }

      if (!data?.user) {
        return {
          ...data,
          user: null,
        };
      }

      queryClient.clear();

      const fallback = buildFallbackSignedInUser(data.user, email);
      setAuthDataError(null);
      setIdentity(fallback.identity);
      setProfileState(fallback.profileState);
      setUser(fallback.user);

      const hydrationRun = ++loginHydrationRun.current;
      const hydrationPromise = fetchSessionData(data.user, true).catch((hydrationError) => {
        console.warn('[Auth.login] foreground identity hydration failed after sign-in:', describeAuthError(hydrationError));
        return null;
      });

      const mergedUser = await Promise.race([
        hydrationPromise,
        new Promise<null>((resolve) => setTimeout(() => resolve(null), LOGIN_ROUTE_LOOKUP_GRACE_MS)),
      ]);

      if (mergedUser && loginHydrationRun.current === hydrationRun) {
        setUser(mergedUser);
        queryClient.invalidateQueries();
        console.debug('[Auth.login] merged user set', { uid: mergedUser.id || mergedUser.user?.id });
        return {
          ...data,
          user: mergedUser,
        };
      }

      hydrationPromise.then((eventualUser) => {
        if (eventualUser && loginHydrationRun.current === hydrationRun) {
          setUser(eventualUser);
          queryClient.invalidateQueries();
          console.debug('[Auth.login] deferred identity hydration completed', { uid: eventualUser.id || eventualUser.user?.id });
        }
      });

      console.debug('[Auth.login] routed with safe fallback while identity hydrates', { uid: fallback.user?.id });
      return {
        ...data,
        user: fallback.user,
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

      console.warn('[Auth.login] failed', {
        errorType,
        message: message || serialized || String(e),
        stack: e?.stack,
        raw: e,
      });

      throw e;
    }
  }, [fetchSessionData, queryClient]);

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
    queryClient.clear();
    setUser(null);
    setIdentity(null);
    setProfileState(null);
    setAuthDataError(null);
  }, [queryClient]);

  const refreshProfile = useCallback(async () => {
    const { data, error } = (await withTimeout(
      supabase.auth.getSession(),
      LOOKUP_TIMEOUT_MS,
      'Session refresh'
    )) as any;

    if (error) throw error;

    const sessionUser = data?.session?.user;
    if (sessionUser) {
      const userData = await fetchSessionData(sessionUser, true);
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
