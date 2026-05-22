/**
 * GEHUConnect Web — Constants
 * Mirrors the Android AppConstants.java for consistency
 */

export const Roles = {
  STUDENT: 'STUDENT',
  ADMIN: 'ADMIN',
  COORDINATOR: 'COORDINATOR',
} as const;

export const EventStatuses = {
  DRAFT: 'DRAFT',
  LIVE: 'LIVE',
  ONGOING: 'ONGOING',
  ENDED: 'ENDED',
  COMPLETED: 'COMPLETED',
} as const;

export const RegStatuses = {
  REGISTERED: 'REGISTERED',
  PAYMENT_PENDING: 'PAYMENT_PENDING',
  PENDING: 'PENDING',
  ACCEPTED: 'ACCEPTED',
} as const;

export const TeamStatus = {
  COMPLETE: 'COMPLETE',
  INCOMPLETE: 'INCOMPLETE',
  OPEN: 'OPEN',
} as const;

export const Modes = {
  INDIVIDUAL: 'individual',
  TEAM: 'team',
  BOTH: 'both',
} as const;

export const PaymentMethods = {
  MANUAL: 'MANUAL',
  RAZORPAY: 'RAZORPAY',
  ERP_GATEWAY: 'ERP_GATEWAY',
} as const;

export const PaymentStatuses = {
  PAYMENT_PENDING: 'PAYMENT_PENDING',
  PAYMENT_SUBMITTED: 'PAYMENT_SUBMITTED',
  PAYMENT_REJECTED: 'PAYMENT_REJECTED',
  VERIFIED: 'VERIFIED',
  REGISTERED: 'REGISTERED',
} as const;

export const NoticeTypes = {
  HOLIDAY: 'holiday',
  EVENT: 'event',
  JOB: 'job',
  GENERAL: 'general',
} as const;

export const InboxTypes = {
  TEAM_INVITE: 'TEAM_INVITE',
  BROADCAST: 'BROADCAST',
  PAYMENT_STATUS: 'PAYMENT_STATUS',
  GENERAL: 'GENERAL',
  UNREAD: 'UNREAD',
} as const;

export const ScheduleStageTypes = {
  REGISTRATION: 'REGISTRATION',
  PERFORMANCE: 'PERFORMANCE',
  JUDGING: 'JUDGING',
  RESULT: 'RESULT',
  CEREMONY: 'CEREMONY',
  CUSTOM: 'CUSTOM',
} as const;

export const ScheduleStageStatuses = {
  UPCOMING: 'UPCOMING',
  ACTIVE: 'ACTIVE',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED',
} as const;

export const Branches = {
  DEHRADUN: 'Dehradun',
  HALDWANI: 'Haldwani',
  BHIMTAL: 'Bhimtal',
  ALL: 'ALL',
} as const;

export const Courses = [
  'B.Tech', 'M.Tech', 'BCA', 'MCA', 'BBA', 'MBA',
  'B.Sc', 'M.Sc', 'BA', 'MA', 'B.Com', 'M.Com',
  'B.Pharm', 'M.Pharm', 'LLB', 'Other'
] as const;

export const Semesters = ['1','2','3','4','5','6','7','8'] as const;

export const Performance = {
  EXCELLENT: 'Excellent',
  GOOD: 'Good',
  AVERAGE: 'Average',
  NEEDS_IMPROVEMENT: 'Needs Improvement',
  ABSENT: 'Absent',
} as const;

export type Role = typeof Roles[keyof typeof Roles];
