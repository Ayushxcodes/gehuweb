"use client";

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { supabase } from '../../../utils/supabaseClient';
import {
  Award, Search, ArrowLeft, RefreshCw, CheckCircle2,
  AlertCircle, Calendar, Users, BarChart3, HelpCircle,
  GraduationCap, BookOpen, Layers, Check, X, ShieldAlert
} from 'lucide-react';

interface MockTestItem {
  test_id: string;
  title: string;
  branch: string;
  course: string;
  semester: string;
  total_questions: number;
  published: boolean;
  results_published: boolean;
  created_at: string;
  test_type?: 'MET' | 'QET';
  custom_code?: string;
}

interface StudentResultItem {
  result_id: string;
  student_id: string;
  student_name: string;
  roll_no: string;
  score: number;
  max_marks: number;
  percentage: number;
  correct: number;
  wrong: number;
  unattempted: number;
  published: boolean;
  submitted_at: string;
  performance?: string;
}

export default function AdminReportsPage() {
  const [loadingTests, setLoadingTests] = useState(false);
  const [loadingResults, setLoadingResults] = useState(false);
  const [publishing, setPublishing] = useState(false);

  const [tests, setTests] = useState<MockTestItem[]>([]);
  const [selectedTestId, setSelectedTestId] = useState<string>('');
  const [results, setResults] = useState<StudentResultItem[]>([]);

  // Navigation / Search Method States
  const [searchMethod, setSearchMethod] = useState<'COHORT' | 'DIRECT'>('COHORT');
  const [searchQuery, setSearchQuery] = useState(''); // Student search
  const [testSearchQuery, setTestSearchQuery] = useState(''); // Test title search

  // Cohort coordinates
  const [branchFilter, setBranchFilter] = useState('ALL');
  const [courseFilter, setCourseFilter] = useState('ALL');
  const [semesterFilter, setSemesterFilter] = useState('ALL');

  // Direct Lookup coordinates
  const [directTestType, setDirectTestType] = useState<'MET' | 'QET'>('MET');
  const [directCodeId, setDirectCodeId] = useState('');

  useEffect(() => {
    // Standard initial load or clean reset on switch
    setSelectedTestId('');
    setResults([]);
    setTests([]);
  }, [searchMethod]);

  useEffect(() => {
    if (selectedTestId) {
      fetchResults(selectedTestId);
    } else {
      setResults([]);
    }
  }, [selectedTestId]);

  async function fetchTests() {
    try {
      setLoadingTests(true);
      let customCode: string | null = null;
      let branch: string | null = null;
      let course: string | null = null;
      let semester: string | null = null;
      let search: string | null = null;

      if (searchMethod === 'DIRECT') {
        const cleanedId = directCodeId.trim();
        if (!cleanedId) {
          alert('Please enter a valid numeric test ID code.');
          setLoadingTests(false);
          return;
        }
        // Force uppercase matching (e.g. MET-0001)
        customCode = `${directTestType}-${cleanedId.padStart(4, '0')}`;
      } else {
        branch = branchFilter === 'ALL' ? null : branchFilter;
        course = courseFilter === 'ALL' ? null : courseFilter;
        semester = semesterFilter === 'ALL' ? null : semesterFilter;
        search = testSearchQuery.trim() || null;
      }

      const { data, error } = await supabase
        .schema('mocks')
        .rpc('api_admin_mock_tests_search', {
          p_branch: branch,
          p_course: course,
          p_semester: semester,
          p_search: search,
          p_custom_code: customCode,
          p_limit: 50
        });

      if (error) throw error;

      const mapped = (data || []).map((t: any) => ({
        ...t,
        branch: t.branch || 'ALL',
        course: t.course || 'ALL',
        semester: String(t.semester || 'ALL')
      }));

      setTests(mapped);
      if (mapped.length > 0) {
        setSelectedTestId(mapped[0].test_id);
      } else {
        setSelectedTestId('');
        setResults([]);
      }
    } catch (err: any) {
      console.error('Error fetching mock tests:', err);
    } finally {
      setLoadingTests(false);
    }
  }

  async function fetchResults(testId: string) {
    try {
      setLoadingResults(true);

      const test = tests.find(t => t.test_id === testId);
      if (!test) return;

      // 1. Fetch all submissions from mock_results
      const { data: resData, error: resError } = await supabase
        .schema('mocks')
        .from('mock_results')
        .select('result_id, student_id, score, max_marks, percentage, correct, wrong, unattempted, published, submitted_at')
        .eq('test_id', testId);

      if (resError) throw resError;

      // 2. Fetch all registered students within the test's target coordinates
      let studentQuery = supabase
        .from('app_profile_state')
        .select('student_id_label, name, roll_no, branch, course, semester')
        .not('student_id_label', 'is', null);

      if (test.branch && test.branch !== 'ALL') {
        studentQuery = studentQuery.ilike('branch', test.branch);
      }
      if (test.course && test.course !== 'ALL') {
        const cUpper = test.course.toUpperCase();
        if (cUpper === 'MCA') {
          studentQuery = studentQuery.in('course', ['MCA', 'Master of Computer Application', 'Master of Computer Applications']);
        } else if (cUpper === 'BCA') {
          studentQuery = studentQuery.in('course', ['BCA', 'Bachelor of Computer Application', 'Bachelor of Computer Applications']);
        } else {
          studentQuery = studentQuery.ilike('course', test.course);
        }
      }
      if (test.semester && test.semester !== 'ALL') {
        studentQuery = studentQuery.eq('semester', Number(test.semester));
      }

      const { data: cohortStudents, error: cohortError } = await studentQuery;
      if (cohortError) throw cohortError;

      // Map submissions by student ID
      const submissionMap: Record<string, any> = {};
      (resData || []).forEach((r: any) => {
        if (r.student_id) {
          submissionMap[r.student_id] = r;
        }
      });

      // 3. Combine both lists so every student in the cohort is accounted for (submitted or absent)
      const mappedResults: StudentResultItem[] = (cohortStudents || []).map((student: any) => {
        const sub = submissionMap[student.student_id_label];

        if (sub) {
          // Submitted state
          return {
            result_id: String(sub.result_id),
            student_id: student.student_id_label,
            student_name: student.name || 'Anonymous Student',
            roll_no: student.roll_no || '-',
            score: Number(sub.score),
            max_marks: Number(sub.max_marks),
            percentage: Number(sub.percentage),
            correct: Number(sub.correct || 0),
            wrong: Number(sub.wrong || 0),
            unattempted: Number(sub.unattempted || 0),
            published: Boolean(sub.published),
            submitted_at: sub.submitted_at || '',
            performance: derivePerformance(sub.percentage)
          };
        } else {
          // Absent state
          return {
            result_id: `absent-${student.student_id_label}`,
            student_id: student.student_id_label,
            student_name: student.name || 'Anonymous Student',
            roll_no: student.roll_no || '-',
            score: 0,
            max_marks: test.total_questions * 2, // 2 marks per question standard fallback
            percentage: 0,
            correct: 0,
            wrong: 0,
            unattempted: 0,
            published: false,
            submitted_at: '',
            performance: 'Absent'
          };
        }
      });

      setResults(mappedResults);
    } catch (err: any) {
      console.error('Error fetching mock results:', err);
      alert('Could not fetch student results: ' + (err.message || String(err)));
    } finally {
      setLoadingResults(false);
    }
  }

  function derivePerformance(pct: number): string {
    if (pct >= 80) return 'Excellent';
    if (pct >= 60) return 'Good';
    if (pct >= 40) return 'Average';
    return 'Needs Improvement';
  }

  async function handlePublishResults() {
    if (!selectedTestId) return;
    const test = tests.find(t => t.test_id === selectedTestId);
    if (!test) return;

    const unpublishedCount = results.filter(r => !r.published).length;
    if (unpublishedCount === 0) {
      alert('All student results for this test are already published!');
      return;
    }

    if (!window.confirm(`Are you sure you want to publish results for "${test.title}"? This will release grades to ${unpublishedCount} students.`)) {
      return;
    }

    try {
      setPublishing(true);
      // Trigger bulk publication PostgreSQL RPC
      const { data, error } = await supabase
        .schema('mocks')
        .rpc('api_admin_publish_results', {
          p_test_id: selectedTestId,
          p_branch: branchFilter === 'ALL' ? null : branchFilter,
          p_course: courseFilter === 'ALL' ? null : courseFilter,
          p_semester: semesterFilter === 'ALL' ? null : semesterFilter
        });

      if (error) throw error;

      alert(`Successfully published results! Release count: ${data || 0}`);

      // Sync list state
      fetchResults(selectedTestId);
      fetchTests();
    } catch (err: any) {
      console.error('Error publishing results:', err);
      alert('Failed to publish results: ' + (err.message || String(err)));
    } finally {
      setPublishing(false);
    }
  }

  const selectedTest = tests.find(t => t.test_id === selectedTestId);

  // Filters calculation
  const getSemestersForCourse = (course: string) => {
    if (course === 'ALL') return [];
    if (course === 'MCA') return [1, 2, 3, 4];
    if (course === 'BCA') return [1, 2, 3, 4, 5, 6];
    return [1, 2, 3, 4, 5, 6, 7, 8];
  };

  const filteredResults = results.filter(r => {
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      if (!r.student_name.toLowerCase().includes(q) && !r.student_id.toLowerCase().includes(q) && !r.roll_no.toLowerCase().includes(q)) {
        return false;
      }
    }
    return true;
  });

  // Aggregates calculation
  const totalSubmissions = results.length;
  const publishedCount = results.filter(r => r.published).length;
  const draftCount = totalSubmissions - publishedCount;

  const classAverageScore = totalSubmissions > 0
    ? (results.reduce((sum, r) => sum + r.score, 0) / totalSubmissions).toFixed(1)
    : '0';

  const classAveragePercentage = totalSubmissions > 0
    ? (results.reduce((sum, r) => sum + r.percentage, 0) / totalSubmissions).toFixed(1)
    : '0';

  const highestScore = totalSubmissions > 0
    ? Math.max(...results.map(r => r.score))
    : 0;

  return (
    <div style={{ maxWidth: 1200, margin: '0 auto', paddingBottom: 100 }}>
      {/* Header */}
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-md)' }}>
          <Link href="/admin/mock-tests/manage" className="btn btn-ghost btn-icon">
            <ArrowLeft size={20} />
          </Link>
          <div>
            <div className="page-title">Mock Reports & Publishing</div>
            <div className="page-subtitle">Publish student scores, audit metrics, and filter target cohorts</div>
          </div>
        </div>
        <button
          className="btn btn-secondary"
          onClick={() => selectedTestId && fetchResults(selectedTestId)}
          disabled={loadingResults || !selectedTestId}
        >
          <RefreshCw size={18} className={loadingResults ? "spin" : ""} /> Refresh
        </button>
      </div>

      {/* Selector and Target Filtration */}
      <div className="grid-2 animate-fade-in-up" style={{ margin: 'var(--space-lg) 0' }}>
        {/* Card 1: Search & Filter Mock Tests */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
          <h3 className="section-title">1. Search & Filter Mock Tests</h3>

          {/* Custom Navigation Tabs */}
          <div style={{
            display: 'flex',
            background: 'var(--color-bg-alt, rgba(255, 255, 255, 0.05))',
            borderRadius: 8,
            padding: 4,
            marginBottom: 10
          }}>
            <button
              className="btn"
              style={{
                flex: 1,
                borderRadius: 6,
                background: searchMethod === 'COHORT' ? 'var(--color-primary, #3b82f6)' : 'transparent',
                color: searchMethod === 'COHORT' ? '#fff' : 'var(--color-text-muted)',
                boxShadow: searchMethod === 'COHORT' ? '0 2px 8px rgba(59, 130, 246, 0.3)' : 'none',
                fontWeight: 600,
                fontSize: 13,
                height: 36,
                padding: '0 var(--space-sm)'
              }}
              onClick={() => setSearchMethod('COHORT')}
            >
              Search by Cohort
            </button>
            <button
              className="btn"
              style={{
                flex: 1,
                borderRadius: 6,
                background: searchMethod === 'DIRECT' ? 'var(--color-primary, #3b82f6)' : 'transparent',
                color: searchMethod === 'DIRECT' ? '#fff' : 'var(--color-text-muted)',
                boxShadow: searchMethod === 'DIRECT' ? '0 2px 8px rgba(59, 130, 246, 0.3)' : 'none',
                fontWeight: 600,
                fontSize: 13,
                height: 36,
                padding: '0 var(--space-sm)'
              }}
              onClick={() => setSearchMethod('DIRECT')}
            >
              Direct ID Lookup
            </button>
          </div>

          {searchMethod === 'COHORT' ? (
            <>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-sm)' }}>
                <div className="input-group">
                  <label className="input-label">Branch Scope</label>
                  <select className="input" value={branchFilter} onChange={e => setBranchFilter(e.target.value)}>
                    <option value="ALL">ALL Branches</option>
                    <option value="Haldwani">Haldwani</option>
                    <option value="Bhimtal">Bhimtal</option>
                    <option value="Dehradun">Dehradun</option>
                  </select>
                </div>
                <div className="input-group">
                  <label className="input-label">Course Scope</label>
                  <select className="input" value={courseFilter} onChange={e => { setCourseFilter(e.target.value); setSemesterFilter('ALL'); }}>
                    <option value="ALL">ALL Courses</option>
                    <option value="B.Tech CSE">B.Tech CSE</option>
                    <option value="BCA">BCA</option>
                    <option value="MCA">MCA</option>
                  </select>
                </div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-sm)', alignItems: 'flex-end' }}>
                <div className="input-group">
                  <label className="input-label">Semester Scope</label>
                  <select className="input" value={semesterFilter} onChange={e => setSemesterFilter(e.target.value)}>
                    <option value="ALL">ALL Semesters</option>
                    {getSemestersForCourse(courseFilter).map(s => <option key={s} value={String(s)}>Sem {s}</option>)}
                  </select>
                </div>
                <div className="input-group">
                  <label className="input-label">Search Test Title</label>
                  <input
                    type="text"
                    className="input"
                    placeholder="Type to search mock..."
                    value={testSearchQuery}
                    onChange={e => setTestSearchQuery(e.target.value)}
                  />
                </div>
              </div>

              <button
                className="btn btn-secondary"
                style={{ width: '100%', height: 42, marginTop: 10, display: 'flex', gap: 8, justifyContent: 'center' }}
                onClick={fetchTests}
                disabled={loadingTests}
              >
                <Search size={16} /> Fetch Mock Tests
              </button>
            </>
          ) : (
            <>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: 'var(--space-sm)' }}>
                <div className="input-group">
                  <label className="input-label">Exam Type</label>
                  <select
                    className="input"
                    value={directTestType}
                    onChange={e => setDirectTestType(e.target.value as 'MET' | 'QET')}
                  >
                    <option value="MET">MET</option>
                    <option value="QET">QET</option>
                  </select>
                </div>
                <div className="input-group">
                  <label className="input-label">Test ID Code</label>
                  <input
                    type="text"
                    className="input"
                    placeholder="e.g. 0001 or 1004"
                    value={directCodeId}
                    onChange={e => setDirectCodeId(e.target.value.replace(/\D/g, ''))} // Numeric only
                  />
                </div>
              </div>

              <button
                className="btn btn-primary"
                style={{ width: '100%', height: 42, marginTop: 10, display: 'flex', gap: 8, justifyContent: 'center' }}
                onClick={fetchTests}
                disabled={loadingTests || !directCodeId}
              >
                <Search size={16} /> Load Test by ID
              </button>
            </>
          )}
        </div>

        {/* Card 2: Filtered Test Selector */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)', justifyContent: 'space-between' }}>
          <div>
            <h3 className="section-title">2. Select Mock Test</h3>
            <div className="input-group">
              <label className="input-label">Active Mocks ({tests.length})</label>
              {loadingTests ? (
                <div className="skeleton" style={{ height: 46 }} />
              ) : tests.length === 0 ? (
                <div style={{ color: 'var(--color-text-muted)', fontSize: 'var(--font-size-sm)', padding: '10px 0' }}>
                  No active tests loaded yet. Use search filters or lookup code on the left!
                </div>
              ) : (
                <select
                  className="input"
                  value={selectedTestId}
                  onChange={e => setSelectedTestId(e.target.value)}
                >
                  {tests.map(t => (
                    <option key={t.test_id} value={t.test_id}>
                      {t.title} [{t.custom_code || t.test_id}]
                    </option>
                  ))}
                </select>
              )}
            </div>

            {selectedTest && (
              <>
                <div style={{ display: 'flex', gap: 'var(--space-md)', flexWrap: 'wrap', marginTop: 15 }}>
                  <div className="chip">
                    <Layers size={14} /> {selectedTest.course} / {selectedTest.branch} (Sem {selectedTest.semester})
                  </div>
                  <div className="chip" style={{ background: selectedTest.test_type === 'QET' ? 'rgba(59, 130, 246, 0.12)' : 'rgba(16, 185, 129, 0.12)', color: selectedTest.test_type === 'QET' ? '#3b82f6' : '#10b981' }}>
                    <ShieldAlert size={14} /> {selectedTest.test_type === 'QET' ? 'QET' : 'MET'}
                  </div>
                  <div className="chip">
                    <BookOpen size={14} /> {selectedTest.total_questions} Questions
                  </div>
                  <div className="chip">
                    <Calendar size={14} /> {selectedTest.results_published ? 'Results Released' : 'Pending Publication'}
                  </div>
                </div>

                {selectedTest.test_type === 'QET' && (
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 10,
                    background: 'rgba(59, 130, 246, 0.06)',
                    border: '1px solid rgba(59, 130, 246, 0.12)',
                    borderRadius: 8,
                    padding: '10px 14px',
                    marginTop: 15,
                    fontSize: 12,
                    color: '#60a5fa',
                    lineHeight: 1.4
                  }}>
                    <HelpCircle size={16} style={{ color: '#3b82f6', flexShrink: 0 }} />
                    <span>
                      <strong>Quick Exam Test (QET):</strong> Results are normally published by instructors. Admin bypass publishing is active.
                    </span>
                  </div>
                )}
              </>
            )}
          </div>

          <button
            className="btn btn-primary"
            style={{ width: '100%', height: 46, marginTop: 15 }}
            disabled={publishing || !selectedTestId || results.length === 0}
            onClick={handlePublishResults}
          >
            {publishing ? <RefreshCw size={16} className="spin" /> : <Award size={16} />}
            Publish Results for Selected Test
          </button>
        </div>
      </div>

      {/* Aggregate Stats Cards */}
      {selectedTestId && results.length > 0 && (
        <div className="grid-4 animate-fade-in-up" style={{ marginBottom: 'var(--space-lg)' }}>
          <div className="stat-card">
            <div className="stat-icon" style={{ background: 'rgba(34, 211, 238, 0.12)', color: 'var(--color-accent)' }}>
              <Users size={20} />
            </div>
            <div>
              <div className="stat-value">{totalSubmissions}</div>
              <div className="stat-label">Submissions</div>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon" style={{ background: 'rgba(16, 185, 129, 0.12)', color: 'var(--color-success)' }}>
              <CheckCircle2 size={20} />
            </div>
            <div>
              <div className="stat-value">{publishedCount}</div>
              <div className="stat-label">Published</div>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon" style={{ background: 'rgba(245, 158, 11, 0.12)', color: 'var(--color-warning)' }}>
              <AlertCircle size={20} />
            </div>
            <div>
              <div className="stat-value">{draftCount}</div>
              <div className="stat-label">Pending Release</div>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon" style={{ background: 'rgba(59, 130, 246, 0.12)', color: 'var(--color-info)' }}>
              <BarChart3 size={20} />
            </div>
            <div>
              <div className="stat-value">{classAveragePercentage}%</div>
              <div className="stat-label">Class Average</div>
            </div>
          </div>
        </div>
      )}

      {/* Results Table Section */}
      <div className="card animate-fade-in-up" style={{ padding: 'var(--space-lg)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-md)', flexWrap: 'wrap', gap: 'var(--space-md)' }}>
          <h3 className="section-title" style={{ margin: 0 }}>Student Submissions List</h3>
          <div className="input-group" style={{ width: 280 }}>
            <div className="search-container" style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
              <Search style={{ position: 'absolute', left: 12, color: 'var(--color-text-muted)' }} size={16} />
              <input
                type="text"
                className="input"
                style={{ paddingLeft: 38, width: '100%', height: 38, fontSize: 'var(--font-size-xs)' }}
                placeholder="Search name, roll, or ID..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
              />
            </div>
          </div>
        </div>

        {loadingResults ? (
          <div className="skeleton" style={{ height: 250 }} />
        ) : !selectedTestId ? (
          <div className="empty-state">
            <HelpCircle size={40} className="empty-state-icon" />
            <div className="empty-state-title">No Mock Test Selected</div>
            <div className="empty-state-subtitle">Select a mock test from the dropdown above to view student analytics.</div>
          </div>
        ) : filteredResults.length === 0 ? (
          <div className="empty-state">
            <Users size={40} className="empty-state-icon" />
            <div className="empty-state-title">No Submissions Recorded</div>
            <div className="empty-state-subtitle">No students have submitted answers for this test or matched your search filters yet.</div>
          </div>
        ) : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Student Info</th>
                  <th>Roll / Student ID</th>
                  <th>Answers Split</th>
                  <th>Obtained Marks</th>
                  <th>Percentage</th>
                  <th>Performance</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {filteredResults.map(r => (
                  <tr key={r.result_id}>
                    <td style={{ fontWeight: 600 }}>{r.student_name}</td>
                    <td>
                      <div style={{ display: 'flex', flexDirection: 'column' }}>
                        <span>{r.roll_no}</span>
                        <span style={{ fontSize: 10, color: 'var(--color-text-muted)' }}>{r.student_id}</span>
                      </div>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: 6, fontSize: 11, fontWeight: 500 }}>
                        <span style={{ color: 'var(--color-success)' }}>{r.correct} C</span>
                        <span style={{ color: 'var(--color-error)' }}>{r.wrong} W</span>
                        <span style={{ color: 'var(--color-text-muted)' }}>{r.unattempted} U</span>
                      </div>
                    </td>
                    <td style={{ fontWeight: 600 }}>{r.performance === 'Absent' ? '-' : `${r.score} / ${r.max_marks}`}</td>
                    <td style={{ fontWeight: 600, color: r.performance === 'Absent' ? 'var(--color-text-muted)' : 'var(--color-accent)' }}>{r.performance === 'Absent' ? '-' : `${r.percentage}%`}</td>
                    <td>
                      <span className="badge" style={{
                        background: r.performance === 'Excellent' ? 'rgba(16, 185, 129, 0.15)' :
                                    r.performance === 'Good' ? 'rgba(59, 130, 246, 0.15)' :
                                    r.performance === 'Average' ? 'rgba(245, 158, 11, 0.15)' :
                                    r.performance === 'Absent' ? 'rgba(239, 68, 68, 0.12)' : 'rgba(239, 68, 68, 0.15)',
                        color: r.performance === 'Excellent' ? '#10b981' :
                               r.performance === 'Good' ? '#3b82f6' :
                               r.performance === 'Average' ? '#f59e0b' : '#ef4444',
                      }}>
                        {r.performance}
                      </span>
                    </td>
                    <td>
                      <span className="badge" style={{
                        background: r.performance === 'Absent' ? 'rgba(239, 68, 68, 0.12)' : r.published ? 'rgba(16, 185, 129, 0.15)' : 'rgba(156, 163, 175, 0.15)',
                        color: r.performance === 'Absent' ? '#ef4444' : r.published ? '#10b981' : '#9ca3af',
                      }}>
                        {r.performance === 'Absent' ? 'Absent' : r.published ? 'Released' : 'Draft'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
