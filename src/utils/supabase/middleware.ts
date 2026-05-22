import { createServerSupabaseClient } from './server';

// Helper to extract session information inside a Next.js middleware or edge handler.
// Usage example in middleware.ts (root):
// const { data } = await getSessionFromHeaders(request.headers);
export async function getSessionFromHeaders(headers: Headers) {
  const cookie = headers.get('cookie') || undefined;
  const supabase = createServerSupabaseClient(cookie);
  try {
    const session = await supabase.auth.getSession();
    return session;
  } catch (e) {
    return { data: null, error: e } as any;
  }
}

// Basic guard you can call from middleware to require authentication.
export async function requireAuthFromHeaders(headers: Headers) {
  const { data, error } = await getSessionFromHeaders(headers);
  if (error || !data?.session) {
    return { authenticated: false, data, error };
  }
  return { authenticated: true, data, error };
}

export default { getSessionFromHeaders, requireAuthFromHeaders };