"use client";

import React from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../../providers/AuthProvider';
import { supabase } from '../../../utils/supabaseClient';
import {
  Award, Calendar, CheckCircle2, ChevronRight, HelpCircle,
  BarChart3, RefreshCw, Layers, BookOpen, AlertCircle,
  Clock, Check, X, ShieldAlert
} from 'lucide-react';

interface ResultFeedItem {
  result_id: string;
  test_id: string;
  title: string;
  start_at: string;
  submitted_at: string | null;
  score: number;
  max_marks: number;
  percentage: number;
  correct: number;
  wrong: number;
  unattempted: number;
  test_type?: 'MET' | 'QET';
}

export default function ResultsPage() {
  const { identity, loading: authLoading } = useAuth();
  const resultsQuery = useQuery({
    queryKey: ['student-results-feed', identity?.auth_user_id || identity?.student_id || 'current'],
    enabled: !authLoading,
    queryFn: async ({ signal }) => {
      const { data, error } = await supabase
        .schema('mocks')
        .rpc('api_student_results_feed', {
          p_limit: 50
        })
        .abortSignal(signal);

      if (error) throw error;

      return (data || []).map((r: any) => ({
        ...r,
        result_id: String(r.result_id),
        score: Number(r.score || 0),
        max_marks: Number(r.max_marks || 0),
        percentage: Number(r.percentage || 0),
        correct: Number(r.correct || 0),
        wrong: Number(r.wrong || 0),
        unattempted: Number(r.unattempted || 0),
        test_type: r.test_type || 'MET'
      })) as ResultFeedItem[];
    },
  });

  const results = resultsQuery.data || [];
  const loading = authLoading || (resultsQuery.isPending && results.length === 0);
  const refreshing = resultsQuery.isFetching && !loading;

  function derivePerformance(pct: number, isAbsent: boolean): string {
    if (isAbsent) return 'Absent';
    if (pct >= 80) return 'Excellent';
    if (pct >= 60) return 'Good';
    if (pct >= 40) return 'Average';
    return 'Needs Improvement';
  }

  function deriveMetGrade(pct: number, isAbsent: boolean): { grade: string; color: string } {
    if (isAbsent) return { grade: 'ABSENT', color: '#ef4444' };
    if (pct >= 90) return { grade: 'A+', color: '#10b981' };
    if (pct >= 80) return { grade: 'A', color: '#10b981' };
    if (pct >= 70) return { grade: 'B+', color: '#3b82f6' };
    if (pct >= 60) return { grade: 'B', color: '#3b82f6' };
    if (pct >= 50) return { grade: 'C', color: '#f59e0b' };
    if (pct >= 33) return { grade: 'D', color: '#f59e0b' };
    return { grade: 'FAILED', color: '#ef4444' };
  }

  const renderSkeleton = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
      {[1, 2].map(i => (
        <div key={i} className="card skeleton" style={{ height: 160, border: 'none' }} />
      ))}
    </div>
  );

  // Aggregates calculation
  const totalExams = results.length;
  const classAveragePercentage = totalExams > 0
    ? (results.reduce((sum, r) => sum + r.percentage, 0) / totalExams).toFixed(1)
    : '0';

  const highestScore = totalExams > 0
    ? Math.max(...results.map(r => r.score))
    : 0;

  const highestPercentage = totalExams > 0
    ? Math.max(...results.map(r => r.percentage))
    : 0;

  return (
    <div style={{ maxWidth: 960, margin: '0 auto', paddingBottom: 100 }} className="animate-fade-in-up">
      {/* Header Banner */}
      <div className="page-header" style={{ marginBottom: 'var(--space-lg)' }}>
        <div>
          <div className="page-title">Personal Mock Examination Results</div>
          <div className="page-subtitle">Review score distributions, performance indicators, and dynamic feedback card metrics</div>
        </div>
        <button
          className="btn btn-secondary"
          onClick={() => resultsQuery.refetch()}
          disabled={loading}
        >
          <RefreshCw size={16} className={loading || refreshing ? "spin" : ""} /> Refresh Results
        </button>
      </div>

      {/* Aggregate Stats Cards */}
      {!loading && totalExams > 0 && (
        <div className="grid-3 animate-fade-in-up" style={{ marginBottom: 'var(--space-lg)' }}>
          <div className="stat-card">
            <div className="stat-icon" style={{ background: 'rgba(34, 211, 238, 0.12)', color: 'var(--color-accent)' }}>
              <CheckCircle2 size={20} />
            </div>
            <div>
              <div className="stat-value">{totalExams}</div>
              <div className="stat-label">Exams Evaluated</div>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon" style={{ background: 'rgba(59, 130, 246, 0.12)', color: 'var(--color-info)' }}>
              <BarChart3 size={20} />
            </div>
            <div>
              <div className="stat-value">{classAveragePercentage}%</div>
              <div className="stat-label">Average Performance</div>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon" style={{ background: 'rgba(16, 185, 129, 0.12)', color: 'var(--color-success)' }}>
              <Award size={20} />
            </div>
            <div>
              <div className="stat-value">{highestPercentage}%</div>
              <div className="stat-label">Highest Score</div>
            </div>
          </div>
        </div>
      )}

      {/* Results Dynamic List */}
      {loading ? (
        renderSkeleton()
      ) : totalExams === 0 ? (
        <div className="empty-state card">
          <Award size={40} className="empty-state-icon" />
          <div className="empty-state-title">No Scorecards Released</div>
          <div className="empty-state-subtitle">There are no published mock results associated with your profile at this time. Only evaluated results released by teachers are shown here.</div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
          {results.map(r => {
            const isAbsent = !r.submitted_at;
            const isQET = r.test_type === 'QET';
            const isMET = r.test_type === 'MET';

            const performance = derivePerformance(r.percentage, isAbsent);
            const metGrade = deriveMetGrade(r.percentage, isAbsent);

            // Dynamic card colors matching Android app performance tiers
            const getPerformanceStyles = (perf: string) => {
              switch (perf) {
                case 'Excellent':
                  return {
                    border: '1px solid rgba(16, 185, 129, 0.3)',
                    badgeBg: 'rgba(16, 185, 129, 0.15)',
                    badgeColor: '#10b981',
                    glow: '0 0 16px rgba(16, 185, 129, 0.1)'
                  };
                case 'Good':
                  return {
                    border: '1px solid rgba(59, 130, 246, 0.3)',
                    badgeBg: 'rgba(59, 130, 246, 0.15)',
                    badgeColor: '#3b82f6',
                    glow: '0 0 16px rgba(59, 130, 246, 0.1)'
                  };
                case 'Average':
                  return {
                    border: '1px solid rgba(245, 158, 11, 0.3)',
                    badgeBg: 'rgba(245, 158, 11, 0.15)',
                    badgeColor: '#f59e0b',
                    glow: '0 0 16px rgba(245, 158, 11, 0.1)'
                  };
                case 'Absent':
                default:
                  return {
                    border: '1px solid rgba(239, 68, 68, 0.3)',
                    badgeBg: 'rgba(239, 68, 68, 0.15)',
                    badgeColor: '#ef4444',
                    glow: '0 0 16px rgba(239, 68, 68, 0.1)'
                  };
              }
            };

            const styles = getPerformanceStyles(performance);

            return (
              <div
                key={r.result_id}
                className="card flex flex-col gap-md"
                style={{
                  border: isAbsent ? '1px solid rgba(239, 68, 68, 0.3)' : styles.border,
                  boxShadow: isAbsent ? '0 0 16px rgba(239, 68, 68, 0.08)' : styles.glow,
                  padding: 'var(--space-lg)'
                }}
              >
                {/* Card Title & Performance Badge */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 'var(--space-sm)' }}>
                  <div>
                    <h3 className="card-title" style={{ fontSize: 'var(--font-size-lg)', display: 'flex', alignItems: 'center', gap: 8 }}>
                      {r.title}
                      <span className="chip" style={{
                        fontSize: 10,
                        padding: '2px 8px',
                        background: isQET ? 'rgba(59, 130, 246, 0.12)' : 'rgba(16, 185, 129, 0.12)',
                        color: isQET ? '#3b82f6' : '#10b981',
                        border: 'none',
                        fontWeight: 700
                      }}>
                        {isQET ? 'QET' : 'MET'}
                      </span>
                    </h3>
                    <div style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)', display: 'flex', gap: 12, marginTop: 2, flexWrap: 'wrap' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 4, color: isAbsent ? 'var(--color-error, #ef4444)' : 'var(--color-text-muted)' }}>
                        <Calendar size={12} />
                        {isAbsent ? 'Status: Did Not Appear (Absent)' : `Submitted: ${new Date(r.submitted_at!).toLocaleString()}`}
                      </span>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><BookOpen size={12} /> ID: mock_exam_{r.test_id}</span>
                    </div>
                  </div>

                  <span className="badge" style={{
                    background: isAbsent ? 'rgba(239, 68, 68, 0.15)' : styles.badgeBg,
                    color: isAbsent ? '#ef4444' : styles.badgeColor,
                    padding: '6px 12px',
                    fontSize: 'var(--font-size-xs)',
                    fontWeight: 700
                  }}>
                    {isAbsent ? 'ABSENT' : performance}
                  </span>
                </div>

                {/* Score breakdown & Progress Indicators */}
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 240px', gap: 'var(--space-lg)', alignItems: 'center', borderTop: '1px solid var(--color-border)', paddingTop: 'var(--space-md)' }}>

                  {/* Detailed split metrics */}
                  <div style={{ display: 'flex', gap: 'var(--space-xl)', flexWrap: 'wrap' }}>
                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                      <span style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>Obtained Score</span>
                      <span style={{ fontSize: 'var(--font-size-xl)', fontWeight: 800, color: isAbsent ? 'var(--color-text-muted)' : 'var(--color-text-primary)' }}>
                        {isAbsent ? '0' : r.score}{' '}
                        <span style={{ fontSize: 'var(--font-size-sm)', fontWeight: 500, color: 'var(--color-text-muted)' }}>/ {r.max_marks}</span>
                      </span>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                      <span style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>Answers Split</span>
                      {isAbsent ? (
                        <div className="flex items-center gap-sm" style={{ marginTop: 4 }}>
                          <span className="badge badge-error" style={{ fontSize: 10, fontWeight: 700, padding: '3px 8px' }}>
                            {isQET ? 'Poor (Absent)' : 'FAILED (Absent)'}
                          </span>
                        </div>
                      ) : (
                        <div className="flex items-center gap-sm" style={{ marginTop: 4 }}>
                          <span className="badge badge-success" style={{ fontSize: 10, fontWeight: 700 }}>{r.correct} Correct</span>
                          <span className="badge badge-error" style={{ fontSize: 10, fontWeight: 700 }}>{r.wrong} Wrong</span>
                          <span className="badge" style={{ fontSize: 10, fontWeight: 700 }}>{r.unattempted} Unattempted</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Percentage / Grade Progress Bar */}
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 'var(--space-md)' }}>
                    {isMET ? (
                      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
                        <span style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>MET Grade</span>
                        <span style={{ fontSize: 'var(--font-size-2xl)', fontWeight: 955, color: metGrade.color }}>{metGrade.grade}</span>
                      </div>
                    ) : (
                      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
                        <span style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)', fontWeight: 600, textTransform: 'uppercase' }}>Overall Score</span>
                        <span style={{ fontSize: 'var(--font-size-2xl)', fontWeight: 900, color: isAbsent ? '#ef4444' : styles.badgeColor }}>
                          {isAbsent ? '0%' : `${r.percentage}%`}
                        </span>
                      </div>
                    )}

                    {/* Dynamic styled mini bar */}
                    <div style={{ width: 6, height: 48, background: 'var(--color-border)', borderRadius: 'var(--radius-full)', overflow: 'hidden', position: 'relative' }}>
                      <div style={{
                        position: 'absolute',
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: isAbsent ? '0%' : `${r.percentage}%`,
                        background: isMET ? metGrade.color : (isAbsent ? '#ef4444' : styles.badgeColor),
                        borderRadius: 'var(--radius-full)'
                      }} />
                    </div>
                  </div>

                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
