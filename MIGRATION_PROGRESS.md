# GEHU Connect: Migration Progress & Active Specifications

This document tracks all discussions, plans, schemas, and policy definitions step-by-step. It is updated continuously so that no context is ever lost during our modernization process.

---

## 📅 Active Discussion Timeline

### May 22, 2026 — Discussion Round: Architecture & Schema Auditing
* **Topic:** Schema extraction, next-step page migrations, and strict security compliance.
* **Core Decisions:**
  1. **Source of Truth Schema:** We will fetch the SQL schema and migrations from the local Android project repository at `C:\Users\Pankaj\AndroidStudioProjects\GEHUConnect\supabase` and copy them directly into `E:\Major Project\gehuweb\supabase\`. This resolves the schema lack inside the web workspace.
  2. **Page Migration Strategy:** The dynamic events, event creation, mock test creation, and notices modules are currently stubs in `gehuweb`. We will port them sequentially from the stable Vite React project in `GEHUConnect_WEB` into `gehuweb` as secure TypeScript (`.tsx`) App Router pages.
  3. **Operational Containerization:** Maintain clean local environments using a `Dockerfile` and `docker-compose.yml` optimized with the `bun` runtime.

---

## 🗂️ 1. Database Schema & Policy Reference

By copying the SQL scripts from your Android GEHUConnect project, we establish the following structural components:

### A. Academic & User Core Layout
* **`student_core`:** Key immutable ID is `stu_student_id`. Handles dob constraints, Category/Gender constraints, and profile photo metadata.
* **`student_contact`:** Hardened unique constraints for `@` domains on `stu_official_email` and primary contact phone numbers.
* **`student_enrollment_current`:** Tracks enrollment roll numbers, branch mappings (`stu_branch_master`), course levels (`UG`, `PG`), specialization master references, and current academic year/semester (1 to 12).
* **`employee_core`:** Handles faculty and admin accounts with immutable `emp_employee_id` blocks.

### B. Mock Test Schema
* **`mocks.mock_tests`:** 
  - Tracks custom APTITUDE and ENGLISH markings (`marking_aptitude_per_q`, `marking_english_per_q`).
  - Implements negative marking triggers with arrays (`negative_apply_to`).
  - Supports CSV and manual creation modes (`source`).
* **`mocks.mock_test_questions`:**
  - Standardizes A/B/C/D option fields and handles solution walkthrough content.
* **`mocks.mock_results`:**
  - Maintains `opt_map` (JSONB letter checks) and session metrics.

---

## 📋 2. Actionable Step-by-Step Execution Plan

We will perform our migration in discrete steps. We will **pause for your approval at each step** before writing any new code:

### 📍 Step 1: Copying and Syncing SQL Schemas
* **Action:** Copy `C:\Users\Pankaj\AndroidStudioProjects\GEHUConnect\supabase\` into `E:\Major Project\gehuweb\supabase\`.
* **Objective:** Ensure all table schemas, RLS policies, and triggers are local to the Next.js workspace for reference.

### 📍 Step 2: Creating TypeScript Type Declarations (`src/types/`)
* **Action:** Declare strict types for `student_core`, `employee_core`, `mock_tests`, `mock_results`, `events`, and `notices`.
* **Objective:** Remove all `any` usage from client fetchers and page props.

### 📍 Step 3: Administrative Mock Tests TSX Migration
* **Action:** Port `/admin/mock-tests/manual` and `/admin/mock-tests/csv` flows.
* **Objective:** Integrate PapaParse CSV validation and the strict DB dual-write logic in clean TSX.

### 📍 Step 4: Events & Notice Board Migration
* **Action:** Port Event Creation (`/admin/events/new`), Event details control panels, Notice detail pages, and FCM registration functions.
* **Objective:** Ensure event listings and notices are fully responsive.

### 📍 Step 5: Security Debug Shield & Sentry Setup
* **Action:** Build the `SecurityShield` (lock right-clicks, F12, and console logs) and configure `@sentry/nextjs`.
* **Objective:** Protect the production build from inspect-element tampering.

### 📍 Step 6: Docker Sandbox Containerization
* **Action:** Set up the multi-stage `Dockerfile` and `docker-compose.yml` leveraging `bun`.
* **Objective:** Clean isolation and single-command local sandbox execution.
