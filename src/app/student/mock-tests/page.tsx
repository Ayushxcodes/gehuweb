"use client";

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../../providers/AuthProvider';
import { supabase } from '../../../utils/supabaseClient';
import {
  Award, Play, Calendar, CheckCircle2, AlertCircle,
  HelpCircle, BookOpen, Layers, Clock, Monitor, RefreshCw
} from 'lucide-react';

interface MockFeedItem {
  test_id: string;
  title: string;
  branch: string;
  course: string;
  semester: string;
  start_at: string;
  duration_minutes: number;
  status: string;
  results_published: boolean;
  requires_web_proctoring: boolean;
  my_locked: boolean;
  my_published: boolean;
  my_started_at: string | null;
  my_submitted_at: string | null;
  my_score: number | null;
  my_percentage: number | null;
  my_hardware_verified?: boolean;
  my_hardware_camera_ok?: boolean;
  my_hardware_mic_ok?: boolean;
}

export default function MockTestsPage() {
  const { identity, profileState, loading: authLoading } = useAuth();
  const [activeTab, setActiveTab] = useState<'ongoing' | 'upcoming' | 'finished'>('ongoing');
  const [now, setNow] = useState<Date>(new Date());
  const mockFeedQuery = useQuery({
    queryKey: ['student-mock-feed', identity?.auth_user_id || identity?.student_id || 'current'],
    enabled: !authLoading,
    queryFn: async ({ signal }) => {
      const { data, error } = await supabase
        .schema('mocks')
        .rpc('api_student_mock_feed', {
          p_limit: 50
        })
        .abortSignal(signal);

      if (error) throw error;
      return (data || []) as MockFeedItem[];
    },
  });

  const tests = mockFeedQuery.data || [];
  const loading = authLoading || (mockFeedQuery.isPending && tests.length === 0);
  const refreshing = mockFeedQuery.isFetching && !loading;

  // Sync clock for upcoming countdown timers and active ranges
  useEffect(() => {
    const timer = setInterval(() => {
      setNow(new Date());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Countdown clock calculation utility
  function getCountdownString(targetDateStr: string): string {
    const diff = new Date(targetDateStr).getTime() - now.getTime();
    if (diff <= 0) return '00:00:00';

    const hrs = Math.floor(diff / 3600000);
    const mins = Math.floor((diff % 3600000) / 60000);
    const secs = Math.floor((diff % 60000) / 1000);

    const pad = (n: number) => String(n).padStart(2, '0');
    return `${pad(hrs)}:${pad(mins)}:${pad(secs)}`;
  }

  function derivePerformance(pct: number): string {
    if (pct >= 80) return 'Excellent';
    if (pct >= 60) return 'Good';
    if (pct >= 40) return 'Average';
    return 'Needs Improvement';
  }

  // Keyset categorization based on database states and schedules
  const ongoingTests = tests.filter(t => {
    const start = new Date(t.start_at).getTime();
    const end = start + (t.duration_minutes * 60 * 1000);
    const currentTime = now.getTime();

    // Ongoing if it has started, not expired, and has not been submitted or locked
    return currentTime >= start && currentTime < end && !t.my_submitted_at && !t.my_locked;
  });

  const upcomingTests = tests.filter(t => {
    const start = new Date(t.start_at).getTime();
    return now.getTime() < start;
  });

  const finishedTests = tests.filter(t => {
    const start = new Date(t.start_at).getTime();
    const end = start + (t.duration_minutes * 60 * 1000);
    const currentTime = now.getTime();

    // Finished if submitted, locked, or expired
    return t.my_submitted_at || t.my_locked || currentTime >= end;
  });

  const renderSkeleton = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
      {[1, 2, 3].map(i => (
        <div key={i} className="card skeleton" style={{ height: 120, border: 'none' }} />
      ))}
    </div>
  );

  return (
    <div style={{ maxWidth: 960, margin: '0 auto', paddingBottom: 100 }} className="animate-fade-in-up">
      {/* Header Banner */}
      <div className="page-header" style={{ marginBottom: 'var(--space-lg)' }}>
        <div>
          <div className="page-title">Assigned Mock Examinations</div>
          <div className="page-subtitle">
            Target Coordinates: {profileState?.course || 'ALL'} / {profileState?.branch || 'ALL'} (Semester {profileState?.semester || 'ALL'})
          </div>
        </div>
        <div style={{ display: 'flex', gap: 'var(--space-md)' }}>
          <Link href="/student/mock-tests/readiness-check" className="btn btn-secondary" style={{ background: 'var(--color-bg-surface)', border: '1px solid var(--color-border)', display: 'flex', alignItems: 'center', gap: 6 }}>
            <Monitor size={16} /> System Check
          </Link>
          <button
            className="btn btn-primary"
            onClick={() => mockFeedQuery.refetch()}
            disabled={loading}
            style={{ display: 'flex', alignItems: 'center', gap: 6 }}
          >
            <RefreshCw size={16} className={loading || refreshing ? "spin" : ""} /> Refresh
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 'var(--space-sm)', borderBottom: '1px solid var(--color-border)', marginBottom: 'var(--space-lg)' }}>
        <button
          className="btn btn-ghost"
          style={{
            borderBottom: activeTab === 'ongoing' ? '2px solid var(--color-accent)' : 'none',
            borderRadius: 'var(--radius-sm) var(--radius-sm) 0 0',
            color: activeTab === 'ongoing' ? 'var(--color-text-primary)' : 'var(--color-text-muted)'
          }}
          onClick={() => setActiveTab('ongoing')}
        >
          Ongoing ({ongoingTests.length})
        </button>
        <button
          className="btn btn-ghost"
          style={{
            borderBottom: activeTab === 'upcoming' ? '2px solid var(--color-accent)' : 'none',
            borderRadius: 'var(--radius-sm) var(--radius-sm) 0 0',
            color: activeTab === 'upcoming' ? 'var(--color-text-primary)' : 'var(--color-text-muted)'
          }}
          onClick={() => setActiveTab('upcoming')}
        >
          Upcoming ({upcomingTests.length})
        </button>
        <button
          className="btn btn-ghost"
          style={{
            borderBottom: activeTab === 'finished' ? '2px solid var(--color-accent)' : 'none',
            borderRadius: 'var(--radius-sm) var(--radius-sm) 0 0',
            color: activeTab === 'finished' ? 'var(--color-text-primary)' : 'var(--color-text-muted)'
          }}
          onClick={() => setActiveTab('finished')}
        >
          Finished ({finishedTests.length})
        </button>
      </div>

      {/* Dynamic Content Rendering */}
      {loading ? (
        renderSkeleton()
      ) : activeTab === 'ongoing' ? (
        ongoingTests.length === 0 ? (
          <div className="empty-state card">
            <Play size={40} className="empty-state-icon" />
            <div className="empty-state-title">No Ongoing Exams</div>
            <div className="empty-state-subtitle">There are no live examinations matching your coordinates currently running.</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
            {ongoingTests.map(t => {
              const isProctored = t.requires_web_proctoring;
              const hasVerified = t.my_hardware_verified;
              const isReady = hasVerified && t.my_hardware_camera_ok && t.my_hardware_mic_ok;
              const hasIssues = hasVerified && (!t.my_hardware_camera_ok || !t.my_hardware_mic_ok);

              return (
                <div key={t.test_id} className="card flex items-center justify-between" style={{ padding: 'var(--space-lg)', border: isProctored ? (isReady ? '1px solid rgba(16, 185, 129, 0.3)' : hasIssues ? '1px solid rgba(239, 68, 68, 0.3)' : '1px solid rgba(245, 158, 11, 0.3)') : '1px solid var(--color-border)' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-sm)' }}>
                      <span className="badge badge-accent">Live Now</span>
                      {isProctored && (
                        <span className="badge badge-error" style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                          <Monitor size={10} /> PC Only
                        </span>
                      )}
                      {isProctored && isReady && <span className="badge badge-success">✅ Hardware Ready</span>}
                      {isProctored && hasIssues && <span className="badge badge-error">❌ Hardware Issues</span>}
                      {isProctored && !hasVerified && <span className="badge badge-warning">⚠️ Verification Required</span>}
                    </div>
                    <h3 className="card-title" style={{ fontSize: 'var(--font-size-lg)', marginTop: 4 }}>{t.title}</h3>
                    <div style={{ display: 'flex', gap: 'var(--space-md)', fontSize: 'var(--font-size-xs)', color: 'var(--color-text-secondary)' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><Clock size={12} /> {t.duration_minutes} Mins</span>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><BookOpen size={12} /> mock_exam_{t.test_id}</span>
                    </div>

                    {isProctored && !isReady && (
                      <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: 4, fontStyle: 'italic' }}>
                        * Please verify webcam and microphone to unlock proctored exam runner.
                      </div>
                    )}
                  </div>

                  <div style={{ display: 'flex', gap: 'var(--space-sm)', alignItems: 'center' }}>
                    {isProctored && (
                      <Link
                        href={`/student/mock-tests/readiness-check?testId=${t.test_id}`}
                        className={`btn ${isReady ? 'btn-ghost' : 'btn-secondary'}`}
                        style={{ display: 'flex', alignItems: 'center', gap: 6 }}
                      >
                        <Monitor size={16} /> {isReady ? 'Check Again' : 'Verify Hardware'}
                      </Link>
                    )}

                    <Link
                      href={`/student/mock-tests/${t.test_id}/run`}
                      className="btn btn-primary"
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 6,
                        pointerEvents: (isProctored && !isReady) ? 'none' : 'auto',
                        opacity: (isProctored && !isReady) ? 0.4 : 1
                      }}
                    >
                      <Play size={16} /> Enter Runner
                    </Link>
                  </div>
                </div>
              );
            })}
          </div>
        )
      ) : activeTab === 'upcoming' ? (
        upcomingTests.length === 0 ? (
          <div className="empty-state card">
            <Calendar size={40} className="empty-state-icon" />
            <div className="empty-state-title">No Upcoming Mocks</div>
            <div className="empty-state-subtitle">No upcoming exams have been scheduled by the department yet. Check back later!</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
            {upcomingTests.map(t => {
              const isProctored = t.requires_web_proctoring;
              const hasVerified = t.my_hardware_verified;
              const isReady = hasVerified && t.my_hardware_camera_ok && t.my_hardware_mic_ok;
              const hasIssues = hasVerified && (!t.my_hardware_camera_ok || !t.my_hardware_mic_ok);

              return (
                <div key={t.test_id} className="card flex items-center justify-between" style={{ padding: 'var(--space-lg)', border: isProctored ? (isReady ? '1px solid rgba(16, 185, 129, 0.3)' : hasIssues ? '1px solid rgba(239, 68, 68, 0.3)' : '1px solid rgba(245, 158, 11, 0.3)') : '1px solid var(--color-border)' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                      <span className="badge badge-warning">Starts In: {getCountdownString(t.start_at)}</span>
                      {isProctored && (
                        <span className="badge badge-error" style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                          <Monitor size={10} /> PC Only
                        </span>
                      )}
                      {isProctored && isReady && <span className="badge badge-success">✅ Hardware Ready</span>}
                      {isProctored && hasIssues && <span className="badge badge-error">❌ Hardware Issues</span>}
                      {isProctored && !hasVerified && <span className="badge badge-warning">⚠️ Verification Required</span>}
                    </div>
                    <h3 className="card-title" style={{ fontSize: 'var(--font-size-lg)', marginTop: 4 }}>{t.title}</h3>
                    <div style={{ display: 'flex', gap: 'var(--space-md)', fontSize: 'var(--font-size-xs)', color: 'var(--color-text-secondary)' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><Clock size={12} /> {t.duration_minutes} Mins</span>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><Calendar size={12} /> {new Date(t.start_at).toLocaleString()}</span>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
                    {isProctored ? (
                      <Link
                        href={`/student/mock-tests/readiness-check?testId=${t.test_id}`}
                        className={`btn ${isReady ? 'btn-ghost' : 'btn-primary'}`}
                        style={{ display: 'flex', alignItems: 'center', gap: 6 }}
                      >
                        <Monitor size={16} /> {isReady ? 'Verify Check' : 'Verify Hardware'}
                      </Link>
                    ) : (
                      <button className="btn btn-secondary" disabled>
                        Scheduled
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )
      ) : (
        finishedTests.length === 0 ? (
          <div className="empty-state card">
            <CheckCircle2 size={40} className="empty-state-icon" />
            <div className="empty-state-title">No Historical Exams</div>
            <div className="empty-state-subtitle">You have not taken or expired any mock examinations yet.</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
            {finishedTests.map(t => {
              const isLocked = t.my_locked || t.my_submitted_at;
              const resultsAvailable = t.my_published || t.results_published;
              const performance = t.my_percentage !== null ? derivePerformance(t.my_percentage) : '';

              return (
                <div key={t.test_id} className="card flex items-center justify-between" style={{ padding: 'var(--space-lg)' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span className="badge badge-success">Completed</span>
                      {resultsAvailable ? (
                        <span className="badge" style={{
                          background: performance === 'Excellent' ? 'rgba(16, 185, 129, 0.15)' :
                                      performance === 'Good' ? 'rgba(59, 130, 246, 0.15)' :
                                      performance === 'Average' ? 'rgba(245, 158, 11, 0.15)' : 'rgba(239, 68, 68, 0.15)',
                          color: performance === 'Excellent' ? '#10b981' :
                                 performance === 'Good' ? '#3b82f6' :
                                 performance === 'Average' ? '#f59e0b' : '#ef4444',
                        }}>
                          {performance} ({t.my_percentage}%)
                        </span>
                      ) : (
                        <span className="badge badge-info">Evaluation Pending</span>
                      )}
                    </div>
                    <h3 className="card-title" style={{ fontSize: 'var(--font-size-lg)', marginTop: 4 }}>{t.title}</h3>
                    <div style={{ display: 'flex', gap: 'var(--space-md)', fontSize: 'var(--font-size-xs)', color: 'var(--color-text-secondary)' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><Clock size={12} /> {t.duration_minutes} Mins</span>
                      {t.my_submitted_at && (
                        <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                          <CheckCircle2 size={12} style={{ color: 'var(--color-success)' }} /> Submitted {new Date(t.my_submitted_at).toLocaleDateString()}
                        </span>
                      )}
                    </div>
                  </div>

                  {resultsAvailable ? (
                    <Link href="/student/results" className="btn btn-secondary">
                      <Award size={16} /> View Scorecard
                    </Link>
                  ) : (
                    <button className="btn btn-ghost" disabled>
                      Locked
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        )
      )}
    </div>
  );
}
