# GEHU Connect — Migration Architecture & Function Reference

Date: 2026-05-22

Purpose: a single-file reference that documents the current client's architecture, lists the primary modules and functions, and gives a concise Next.js migration mapping you can use to implement the App Router migration.

--

## High-level architecture

- Framework: Vite + React (client SPA)
- Router: `react-router-dom` (client-side routing)
- Auth: Supabase Auth + application tables (`app_user_identity`, `app_profile_state`) and RPC `api_auth_route_snapshot`
- Backend: Supabase (RLS, RPCs). Some server logic uses legacy Express elsewhere (see AGENTS.md) but client calls Supabase directly.
- Push: Firebase Cloud Messaging (service worker at `public/firebase-messaging-sw.js`).

## Runtime & environment

- Vite environment variables (replace with Next.js names when migrating):
  - `VITE_SUPABASE_URL` -> `NEXT_PUBLIC_SUPABASE_URL`
  - `VITE_SUPABASE_ANON_KEY` -> `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - Firebase web keys: `VITE_FIREBASE_*` -> keep secrets server-side where required

## Key files (overview)

- App bootstrap: [src/main.jsx](src/main.jsx#L1-L50)
- App routes / layout: [src/App.jsx](src/App.jsx#L1-L300)
- Auth provider: [src/contexts/AuthContext.jsx](src/contexts/AuthContext.jsx#L1-L400)
- Supabase client: [src/utils/supabaseClient.js](src/utils/supabaseClient.js#L1-L200)
- Push utils: [src/utils/pushNotifications.js](src/utils/pushNotifications.js#L1-L400)
- Constants: [src/utils/constants.js](src/utils/constants.js#L1-L200)
- Template engine: [src/utils/AtsTemplateEngine.js](src/utils/AtsTemplateEngine.js#L1-L400)
- Protected routing wrapper: [src/components/ProtectedRoute.jsx](src/components/ProtectedRoute.jsx#L1-L200)
- Sidebar & navigation: [src/components/Sidebar.jsx](src/components/Sidebar.jsx#L1-L400)
- Login page: [src/pages/auth/LoginPage.jsx](src/pages/auth/LoginPage.jsx#L1-L300)

## Module & function reference

Below are the primary exported functions or top-level components and their responsibilities.

- `src/utils/supabaseClient.js` ([file](src/utils/supabaseClient.js#L1-L200))
  - `customFetch(url, options)` — a fetch wrapper with a 30s AbortController and timeout handling used by Supabase client.
  - `supabase` — exported Supabase client created via `createClient(...)` configured with `auth` options and `global.fetch: customFetch`.

- `src/utils/pushNotifications.js` ([file](src/utils/pushNotifications.js#L1-L400))
  - `hasWebPushConfig()` — returns true when required Firebase config + VAPID key are present.
  - `firebaseModules()` — lazy-imports `firebase/app` and `firebase/messaging` modules and caches the promise.
  - `getDeviceId()` — generates / persists a local UUID used to identify the device for token registration.
  - `swUrl()` — builds the service-worker registration URL with Firebase config query params.
  - `appInstance(firebase)` — returns or initializes the firebase app instance.
  - `registerWebPushToken({ requestPermission = false })` — registers a web push token, stores it by calling the Supabase RPC `api_register_fcm_token`, returns status and token.
  - `listenForForegroundPush(callback)` — registers `onMessage` listener for foreground messages; returns an unsubscribe handler.

- `src/utils/constants.js` ([file](src/utils/constants.js#L1-L200))
  - Exports enumerations and arrays used across the app such as `Roles`, `EventStatuses`, `PaymentMethods`, `Branches`, `Courses`, `Semesters`, and `Performance`.

- `src/utils/AtsTemplateEngine.js` ([file](src/utils/AtsTemplateEngine.js#L1-L400))
  - `getHtml(cv)` — primary export. Renders a selected resume template (Mustache-like) with CV data and returns an HTML string.
  - Internal helpers: `esc()` for escaping and template definitions (`templates`) for different resume styles.

- `src/contexts/AuthContext.jsx` ([file](src/contexts/AuthContext.jsx#L1-L400))
  - `withTimeout(promise, timeoutMs, label)` — utility to race a promise against a timeout and provide readable error messages.
  - `retryWithBackoff(fn, attempts = 3, baseDelay = 500)` — retries an async function with exponential backoff and throws last error on failure.
  - `fetchSessionData(authSessionUser)` — core: resolves consolidated auth + identity + profile state for a Supabase auth user. Attempts `api_auth_route_snapshot` RPC first, falls back to table lookups, merges identity & profile state, and returns the merged object.
  - `AuthProvider({ children })` — React provider exposing: `user`, `identity`, `profileState`, `loading`, `authDataError`, `login()`, `register()`, `logout()`, `refreshProfile()`, and boolean helpers `isAdmin`, `isStudent`, `isCoordinator`, `isAuthenticated`, `profileCompleted`, `isPendingVerification`.
  - `login(email, password)` — uses `supabase.auth.signInWithPassword`, then rehydrates merged user data via `fetchSessionData`.
  - `register(email, password)` — wraps `supabase.auth.signUp`.
  - `logout()` — signs out (with timeout fallback) and clears local context state.
  - `refreshProfile()` — re-queries session and `fetchSessionData` to refresh user object.
  - Lifecycle behaviors: subscribes to `supabase.auth.onAuthStateChange`, loads initial session via `supabase.auth.getSession()`, and implements keep-alive token refresh and visibility-based refresh.

- `src/components/ProtectedRoute.jsx` ([file](src/components/ProtectedRoute.jsx#L1-L200))
  - Default export is the component `ProtectedRoute({ children, requiredRole, requireProfileComplete })`.
  - Behavior: shows loading state while context `loading` true; redirects to `/login` if unauthenticated; redirects to `/locked` if identity missing; handles profile completion and pending verification redirects; enforces role checks (`requiredRole === 'ADMIN'` redirects to `/dashboard` when unauthorized).

- `src/components/Sidebar.jsx` ([file](src/components/Sidebar.jsx#L1-L400))
  - `Sidebar()` — Client UI component controlling navigation and logout; manages collapse / mobile state, fetches notification badge count via `supabase.rpc('api_student_notification_badge_count')`, exposes different link sets for `isAdmin` vs students, and performs `logout()`.

- `src/pages/auth/LoginPage.jsx` ([file](src/pages/auth/LoginPage.jsx#L1-L300))
  - `LoginPage()` — local state for `email`, `password`, `rememberMe`, `showPassword`, `loading`, `error`. Key functions: `validateEmail()` and `handleSubmit(e)` which validates input and calls `login(email, password)` from `AuthContext` then routes the user according to `account_type`.

- `src/App.jsx` ([file](src/App.jsx#L1-L400))
  - `App()` — top-level route mapping using `react-router-dom` `Routes`. Uses `ProtectedRoute` for guarded pages and `WithSidebar` wrapper for pages that show the sidebar. Exposes all the student/admin routes mapping to individual page components.
  - `WithSidebar({ children })` — layout wrapper that renders `Sidebar` + main content area.

## Route mapping → Next.js App Router (recommended)

- Use `app/layout.jsx` to wrap the app with `AuthProvider` (client-side provider) and import global CSS (previously in `src/index.css`).
- Map `src/pages/*` to `app/*/page.jsx` following the existing mapping (see NEXTJS_MIGRATION_GUIDE.md). Use nested `layout.jsx` files under `app/admin` and `app/student` to include `Sidebar` and shared UI.
- Convert `ProtectedRoute` behaviors to server-side protection via `middleware.ts` (recommended) and/or server components that call Supabase server helpers to redirect. Keep a client `useAuth()` provider for client-side checks and interactions.

## Migration checklist (concise)

1. Create Next.js app (App Router) and copy `public/`, `components/`, `contexts/`, `utils/`, and `src/pages` into `app/` / `components/` as appropriate.
2. Rename env vars in `.env.local`: `VITE_SUPABASE_URL` → `NEXT_PUBLIC_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` → `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
3. Add `app/layout.jsx` importing global CSS and wrapping with `AuthProvider` (Client Component). Place `'use client'` in providers that use hooks.
4. Move `BrowserRouter` usage out; Next uses file-system routing. Replace route-driven link components with `next/link` and nested layout routing.
5. Migrate `ProtectedRoute` to `middleware.ts` server-side checks and/or server components that `redirect()` when unauthenticated.
6. Keep `src/utils/supabaseClient.js` but adapt `import.meta.env` usages to `process.env.NEXT_PUBLIC_*` and consider a server-only supabase client for server components (service role) when needed.
7. Keep `public/firebase-messaging-sw.js` at `public/` root in Next project.
8. Convert CSS imports: global CSS in `app/layout.jsx`; component CSS into the related client components.
9. Test flows: login, profile setup, admin pages, student pages, push registration.

## Recommended next steps (short)

- Confirm whether you'd like me to scaffold `app/layout.jsx`, `app/page.jsx`, and the first three pages: `/auth/login`, `/student/dashboard`, `/admin/dashboard`.
- Option: I can convert `AuthProvider` into a client provider file (`app/providers/AuthProvider.jsx`) and show an example `middleware.ts` that protects `/admin` and `/student`.

---

File reference: this document was generated by scanning key files under `src/` — see the file links above for the original sources to inspect implementation details while migrating.

If you want, I will now scaffold the Next.js project root and convert the following pages: `auth/login`, `student/dashboard`, `admin/dashboard`.
