import { createBrowserClient } from '@supabase/ssr';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

export const customFetch = async (input: RequestInfo, init?: RequestInit) => {
  const controller = new AbortController();
  const timeoutMs = 30000; // 30s
  const timeoutId = setTimeout(() => controller.abort(new DOMException('Request timeout', 'TimeoutError')), timeoutMs);
  const externalSignal = init?.signal;

  const getInputUrl = (inp: RequestInfo) => {
    try {
      if (typeof inp === 'string') return inp;
      // @ts-ignore
      if (inp?.url) return inp.url;
      return String(inp);
    } catch {
      return 'unknown';
    }
  };

  const abortFromExternalSignal = () => {
    if (!controller.signal.aborted) {
      controller.abort(externalSignal?.reason);
    }
  };

  if (externalSignal?.aborted) {
    abortFromExternalSignal();
  } else {
    externalSignal?.addEventListener('abort', abortFromExternalSignal, { once: true });
  }

  try {
    const response = await fetch(input, { ...init, signal: controller.signal });
    return response;
  } catch (error: any) {
    const requestUrl = getInputUrl(input);
    if (error?.name === 'AbortError' || error?.name === 'TimeoutError') {
      if (externalSignal?.aborted) {
        throw error;
      }
      throw new Error(`Network request to ${requestUrl} timed out after ${timeoutMs / 1000} seconds. Please check your connection.`);
    }
    const message = error?.message || String(error);
    throw new Error(`Fetch to ${requestUrl} failed: ${message}`);
  } finally {
    clearTimeout(timeoutId);
    externalSignal?.removeEventListener('abort', abortFromExternalSignal);
  }
};

const missingMsg = '[supabase] Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_SUPABASE_ANON_KEY environment variables.';

export const supabase = (SUPABASE_URL && SUPABASE_ANON_KEY)
  ? createBrowserClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        fetch: customFetch as any,
      },
    })
  : (function createMissingClientStub() {
      console.error(missingMsg);
      return {
        auth: {
          signInWithPassword: async () => { throw new Error(missingMsg); },
          signUp: async () => { throw new Error(missingMsg); },
          getSession: async () => { throw new Error(missingMsg); },
          signOut: async () => { throw new Error(missingMsg); },
          refreshSession: async () => { throw new Error(missingMsg); },
          onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => {} } } }),
        },
        from: () => ({ select: () => ({ maybeSingle: async () => { throw new Error(missingMsg); } }) }),
      } as any;
    })();

export default supabase;
