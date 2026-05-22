import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';
const SUPABASE_SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

export const customServerFetch = () => async (input: RequestInfo, init?: RequestInit) => {
  const controller = new AbortController();
  const timeoutMs = 30000;
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(input, { ...init, signal: controller.signal });
    return response;
  } catch (error: any) {
    if (error?.name === 'AbortError') {
      throw new Error(`Network request timed out after ${timeoutMs / 1000} seconds. Please check your connection.`);
    }
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
};

export async function createServerSupabaseClient() {
  const cookieStore = await cookies();
  return createServerClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options);
          });
        } catch {
          // This can fail if called from a server component. 
          // The middleware should be handling the setting of tokens.
        }
      },
    },
    global: {
      fetch: customServerFetch() as any,
    },
  });
}

export const serverSupabaseAdmin = SUPABASE_SERVICE_ROLE
  ? createServerClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE, {
      cookies: {
        getAll() { return [] },
        setAll() {}
      },
      global: { fetch: customServerFetch() as any }
    })
  : null;

export default createServerSupabaseClient;
