# GEHU Connect — Pages & Routes Reference

Date: 2026-05-22

Purpose: a concise, single-file reference listing every client route in the current Vite React app, the source file implementing the page, a short description, and notes for migrating to Next.js (App Router).

---

## Conventions

- File links point to the current source under `src/pages/`.
- Routes are listed as they appear in `src/App.jsx` (client-side router).
- Use this file as the canonical mapping when creating `app/*/page.jsx` and nested `layout.jsx` files in Next.js.

## Auth routes

- `/login` — [src/pages/auth/LoginPage.jsx](src/pages/auth/LoginPage.jsx#L1)
  - Description: Login form, remember-email, client-side validation, calls `login()` from `AuthContext`.
  - Next.js note: convert to a Client Component (`'use client'`) at `app/auth/login/page.jsx`.

- `/profile-setup` — [src/pages/auth/ProfileSetupPage.jsx](src/pages/auth/ProfileSetupPage.jsx#L1)
  - Description: Profile completion flow after first sign-up or missing profile state.
  - Next.js note: client component under `app/auth/profile-setup/page.jsx` and server redirection handled in middleware or server component.

- `/pending-verification` — [src/pages/auth/PendingVerificationPage.jsx](src/pages/auth/PendingVerificationPage.jsx#L1)
  - Description: Shown when profile submitted but awaiting verification.

- `/locked` — [src/pages/auth/LockedAccountPage.jsx](src/pages/auth/LockedAccountPage.jsx#L1)
  - Description: Locked account page shown when identity resolution fails or account inactive.

## Student routes

- `/dashboard` — [src/pages/student/DashboardPage.jsx](src/pages/student/DashboardPage.jsx#L1)
  - Description: Student home; shows quick actions (Mock Test, Practice, Results, Resume, Notices, Events).

- `/mock-tests` — [src/pages/student/MockTestsPage.jsx](src/pages/student/MockTestsPage.jsx#L1)
  - Description: List of mock tests.

- `/mock-tests/:testId/run` — [src/pages/student/MockTestRunnerPage.jsx](src/pages/student/MockTestRunnerPage.jsx#L1)
  - Description: Test runner UI. Contains client-only logic and timed interactions.
  - Next.js note: keep as Client Component; consider `app/student/mock-tests/[testId]/run/page.jsx`.

- `/practice` — [src/pages/student/PracticePage.jsx](src/pages/student/PracticePage.jsx#L1)
- `/practice/:topic` — [src/pages/student/PracticeSessionPage.jsx](src/pages/student/PracticeSessionPage.jsx#L1)
  - Description: Practice topics and per-topic sessions.

- `/results` — [src/pages/student/ResultsPage.jsx](src/pages/student/ResultsPage.jsx#L1)
  - Description: Student results and scorecards.

- `/resume` — [src/pages/student/ResumePage.jsx](src/pages/student/ResumePage.jsx#L1)
- `/resume/builder` and `/resume/builder/:id` — [src/pages/student/ResumeBuilderPage.jsx](src/pages/student/ResumeBuilderPage.jsx#L1)
  - Description: CV/resume builder and editor; uses `AtsTemplateEngine` to generate HTML.

- `/notices` — [src/pages/student/NoticesPage.jsx](src/pages/student/NoticesPage.jsx#L1)
- `/notices/:id` — [src/pages/student/NoticeDetailPage.jsx](src/pages/student/NoticeDetailPage.jsx#L1)
  - Description: Notice feed and detail view.

- `/notifications` — [src/pages/student/NotificationsPage.jsx](src/pages/student/NotificationsPage.jsx#L1)
  - Description: In-app notifications list.

- `/events` — [src/pages/student/EventsPage.jsx](src/pages/student/EventsPage.jsx#L1)
- `/events/:id` — [src/pages/student/EventDetailPage.jsx](src/pages/student/EventDetailPage.jsx#L1)
- `/events/:eventId/participate/:compId` — [src/pages/student/EventParticipatePage.jsx](src/pages/student/EventParticipatePage.jsx#L1)
- `/events/:eventId/chat` — [src/pages/student/GroupChatPage.jsx](src/pages/student/GroupChatPage.jsx#L1)
  - Description: Event listings, detail pages, competition participation, and group chat.

- `/event-history` — [src/pages/student/EventHistoryPage.jsx](src/pages/student/EventHistoryPage.jsx#L1)
  - Description: Past events and registrations.

- `/achievements` — [src/pages/student/AchievementsPage.jsx](src/pages/student/AchievementsPage.jsx#L1)
- `/certificates` — [src/pages/student/CertificatesPage.jsx](src/pages/student/CertificatesPage.jsx#L1)
  - Description: Achievements and certificates UI.

- `/mail` — [src/pages/student/MailPage.jsx](src/pages/student/MailPage.jsx#L1)
  - Description: In-app mail/inbox for notices and messages.

- `/feedback` — [src/pages/student/ResumeFeedbackPage.jsx](src/pages/student/ResumeFeedbackPage.jsx#L1)
  - Description: Resume feedback submission UI.

- `/profile/edit` — [src/pages/student/ProfileEditPage.jsx](src/pages/student/ProfileEditPage.jsx#L1)
  - Description: Edit profile page for students.

## Admin routes

- `/admin` — [src/pages/admin/AdminDashboardPage.jsx](src/pages/admin/AdminDashboardPage.jsx#L1)
  - Description: Admin landing (6-card dashboard): Organize, Results, Notices, Feedback, Search Students, Events.

- `/admin/organize` — [src/pages/admin/MockHostSelectionPage.jsx](src/pages/admin/MockHostSelectionPage.jsx#L1)
- `/admin/mock-tests` — [src/pages/admin/AdminMockTestPage.jsx](src/pages/admin/AdminMockTestPage.jsx#L1)
- `/admin/csv-mock` — [src/pages/admin/AdminMockTestPage.jsx](src/pages/admin/AdminMockTestPage.jsx#L1)
  - Description: Mock test management and hosting.

- `/admin/reports` — [src/pages/admin/AdminReportsPage.jsx](src/pages/admin/AdminReportsPage.jsx#L1)
  - Description: Results and report generation.

- `/admin/notices` — [src/pages/admin/AdminNoticesPage.jsx](src/pages/admin/AdminNoticesPage.jsx#L1)
  - Description: Compose and manage notices.

- `/admin/feedback` — [src/pages/admin/AdminFeedbackPage.jsx](src/pages/admin/AdminFeedbackPage.jsx#L1)
  - Description: View admin feedback submissions.

- `/admin/student-search` — [src/pages/admin/StudentSearchSelectionPage.jsx](src/pages/admin/StudentSearchSelectionPage.jsx#L1)
- `/admin/student-search/single` — [src/pages/admin/StudentSingleSearchPage.jsx](src/pages/admin/StudentSingleSearchPage.jsx#L1)
- `/admin/student-search/group` — [src/pages/admin/StudentGroupSearchPage.jsx](src/pages/admin/StudentGroupSearchPage.jsx#L1)
- `/admin/students` — [src/pages/admin/StudentsPage.jsx](src/pages/admin/StudentsPage.jsx#L1)
- `/admin/students/:studentId` — [src/pages/admin/StudentDetailPage.jsx](src/pages/admin/StudentDetailPage.jsx#L1)
  - Description: Student search, single/group search workflows, and student details.

- `/admin/appeals` — [src/pages/admin/AdminAppealsPage.jsx](src/pages/admin/AdminAppealsPage.jsx#L1)
  - Description: Appeals management UI.

- `/admin/events` — [src/pages/admin/ManageEventsPage.jsx](src/pages/admin/ManageEventsPage.jsx#L1)
- `/admin/events/new` — [src/pages/admin/CreateEventPage.jsx](src/pages/admin/CreateEventPage.jsx#L1)
- `/admin/events/:id` — [src/pages/admin/EventControlPage.jsx](src/pages/admin/EventControlPage.jsx#L1)
- `/admin/events/:eventId/control` — [src/pages/admin/EventControlPanelPage.jsx](src/pages/admin/EventControlPanelPage.jsx#L1)
- `/admin/events/:eventId/competitions` — [src/pages/admin/ManageCompetitionsPage.jsx](src/pages/admin/ManageCompetitionsPage.jsx#L1)
- `/admin/events/:eventId/competitions/:compId/control` — [src/pages/admin/EventControlPanelPage.jsx](src/pages/admin/EventControlPanelPage.jsx#L1)
- `/admin/events/:eventId/competitions/:compId/students` — [src/pages/admin/StudentGroupSearchPage.jsx](src/pages/admin/StudentGroupSearchPage.jsx#L1)
- `/admin/events/:eventId/competitions/:compId/attendance` — [src/pages/admin/AdminAttendancePage.jsx](src/pages/admin/AdminAttendancePage.jsx#L1)
- `/admin/events/:eventId/competitions/:compId/results` — [src/pages/admin/AdminResultPublishPage.jsx](src/pages/admin/AdminResultPublishPage.jsx#L1)
- `/admin/events/:eventId/competitions/:compId/announcements` — [src/pages/admin/AdminNoticesPage.jsx](src/pages/admin/AdminNoticesPage.jsx#L1)
- `/admin/events/:eventId/schedule` — [src/pages/admin/AdminSchedulePage.jsx](src/pages/admin/AdminSchedulePage.jsx#L1)
- `/admin/broadcast` — [src/pages/admin/AdminBroadcastPage.jsx](src/pages/admin/AdminBroadcastPage.jsx#L1)
  - Description: Event management, competitions, attendance, result publishing, schedule, and broadcast.

## Shared routes

- `/settings` — [src/pages/shared/SettingsPage.jsx](src/pages/shared/SettingsPage.jsx#L1)
  - Description: Account and app settings.

## Non-route page files (assets & CSS)

- `src/pages/auth/LoginPage.css` — styles for the login page.
- `src/pages/student/MockTestRunner.css` — styles for the mock test runner.

## Notes for migration

- Convert each file into `app/<area>/<...>/page.jsx` or nested routes using dynamic folders (e.g., `app/events/[id]/page.jsx`).
- For interactive pages (mock test runner, chat, resume builder), use Client Components by adding `'use client'` at the top.
- Place shared layout (sidebar + topbar) in `app/layout.jsx` and create `app/admin/layout.jsx` and `app/student/layout.jsx` for area-specific UI.
- Implement `middleware.ts` to guard `/admin` and `/student` paths using server-side session checks or Supabase server client.

---

If you want, I can now scaffold the `app/` structure and convert a selected subset of pages into Next.js files. Which three pages should I convert first? (suggestion: `auth/login`, `student/dashboard`, `admin/dashboard`).
