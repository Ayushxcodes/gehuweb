# 📝 GEHUConnect Developer Log & Technical Debt Tracker

This document serves as a localized, transparent ledger tracking all temporary bypasses, architectural trade-offs, and staged role-restrictions in the GEHUConnect platform. Use this guide to safely revert workarounds when migrating to multi-role environments.

---

## 📌 Active Workaround: `QET_ADMIN_PUBLISH_BYPASS`

| Attribute | Details |
| :--- | :--- |
| **Feature Area** | Mock Test Results Publishing (`/admin/reports`) |
| **Assigned Severity** | Low (Strategic Architecture Bypass) |
| **Target Audience** | Main Exam Cell (Admin) & Instructors (Teachers) |
| **Current Status** | **ACTIVE** (Admin has full bypass clearance to publish QETs) |

---

### 1. Conceptual Context & System Design

The mock test system distinguishes between two primary categories of examinations:
1. **MET (Main Exam Test):** High-stakes institutional exams organized centrally by the Exam Cell. Only administrators (Exam Cell in-charge) have clearance to publish or schedule results.
2. **QET (Quick Exam Test):** Small-scale formative tests or classroom quizzes organized by individual instructors (teachers). The conducting instructor retains sole ownership of when to publish or hide these scores.

#### The Temporary Constraint:
Because the platform currently operates with a **sole Admin operator** (no active multi-instructor accounts are registered in the pilot), a strict restriction blocking the Admin from publishing QETs would paralyze classroom testing flows. Therefore, a **temporary bypass** has been implemented to grant the Admin full QET publishing clearance.

---

### 2. Frontend Implementation & Coordinates

* **Target File:** [`src/app/admin/reports/page.tsx`](file:///E:/Major%20Project/gehuweb/src/app/admin/reports/page.tsx)
* **Code Bypass Location:** Inside the UI rendering for the **Publish Results** action card and the `handlePublishResults` function.
* **Database State:** The `mock_tests` schema tracks `test_type` as either `'MET'` or `'QET'`.

---

### 3. Future Step-by-Step Reversion Blueprint
When the multi-instructor teacher dashboard is ready to deploy, follow these instructions to safely remove the Admin bypass and restrict QET publishing to teachers only:

#### Step 1: Update the Reports UI Selector
Inside [`src/app/admin/reports/page.tsx`](file:///E:/Major%20Project/gehuweb/src/app/admin/reports/page.tsx), locate the Publish Results button. Change the `disabled` logic to explicitly block QETs from being published by the Admin:

```diff
- disabled={publishing || !selectedTestId || results.length === 0}
+ disabled={publishing || !selectedTestId || results.length === 0 || selectedTest.test_type === 'QET'}
```

#### Step 2: Render the Restricted UI Banner
Display a clear warning card to the administrator when a QET is loaded, informing them that publishing is locked to the instructor:

```tsx
{selectedTest.test_type === 'QET' && (
  <div className="alert alert-info" style={{ marginTop: 15 }}>
    <Info size={16} />
    <span>
      Quick Exam Test (QET) results are managed directly by the conducting instructor. 
      Admin role has read-only report access and export clearance.
    </span>
  </div>
)}
```

#### Step 3: Implement Database Security (RLS)
Update the database schema to ensure that only the creator of the QET (matching `created_by = auth.uid()`) can mutate `results_published` for QET tests.

---

*Document created on: May 24, 2026*
