"use client";

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { supabase } from '../../../../utils/supabaseClient';
import { 
  Database, Search, ArrowLeft, RefreshCw, Eye, EyeOff, 
  BookOpen, Trash2, BarChart, X, ClipboardList, Loader2,
  Monitor, Clock
} from 'lucide-react';

interface MockTestItem {
  test_id: string;
  title: string;
  branch: string | null;
  course: string | null;
  semester: number | null;
  total_questions: number;
  published: boolean;
  created_at: string;
  start_at?: string;
  duration_minutes?: number;
  exam_end_at?: string;
  results_published?: boolean;
  requires_web_proctoring?: boolean;
  total_verified_students?: number;
  fully_ready_students?: number;
  students_with_issues?: number;
}

interface TestQuestion {
  qid: string;
  subject_type?: string;
  subject?: string;
  question: string;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  answer_letter?: string;
  answer?: string;
}

export default function ManageMockTestsPage() {
  const router = useRouter();

  const [loading, setLoading] = useState(true);
  const [tests, setTests] = useState<MockTestItem[]>([]);
  
  // Dashboard Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [branchFilter, setBranchFilter] = useState('ALL');
  const [courseFilter, setCourseFilter] = useState('ALL');
  const [semesterFilter, setSemesterFilter] = useState('ALL');
  const [now, setNow] = useState<Date>(new Date());

  // Preview Modal State
  const [selectedQuestionsTest, setSelectedQuestionsTest] = useState<MockTestItem | null>(null);
  const [testQuestions, setTestQuestions] = useState<TestQuestion[]>([]);
  const [loadingQuestions, setLoadingQuestions] = useState(false);

  // Action States
  const [publishingTestId, setPublishingTestId] = useState<string | null>(null);
  const [deletingTestId, setDeletingTestId] = useState<string | null>(null);

  useEffect(() => {
    fetchTests();
    const interval = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(interval);
  }, []);

  async function fetchTests() {
    try {
      setLoading(true);
      // Query from mocks.mock_tests to ensure parity with mobile configurations
      const { data: testData, error: testError } = await supabase
        .schema('mocks')
        .from('mock_tests')
        .select('test_id, title, branch, course, semester, total_questions, published, created_at, start_at, duration_minutes, exam_end_at, results_published, requires_web_proctoring')
        .order('created_at', { ascending: false });

      if (testError) throw testError;

      // Query summaries from ops.v_mock_readiness_summary view
      const { data: summaryData, error: summaryError } = await supabase
        .schema('ops')
        .from('v_mock_readiness_summary')
        .select('*');

      if (summaryError) {
        console.warn('Could not load mock readiness summaries:', summaryError);
      }

      // Merge readiness metrics into mock test feed
      const combined = (testData || []).map((t: any) => {
        const summ = (summaryData || []).find((s: any) => s.test_id === t.test_id);
        return {
          ...t,
          total_verified_students: summ ? Number(summ.total_verified_students) : 0,
          fully_ready_students: summ ? Number(summ.fully_ready_students) : 0,
          students_with_issues: summ ? Number(summ.students_with_issues) : 0
        };
      });

      setTests(combined);
    } catch (err: any) {
      console.error('Error fetching tests:', err);
      alert('Could not fetch mock tests: ' + (err.message || String(err)));
    } finally {
      setLoading(false);
    }
  }

  async function fetchQuestionsForTest(test: MockTestItem) {
    setSelectedQuestionsTest(test);
    setLoadingQuestions(true);
    setTestQuestions([]);
    
    try {
      // Fetch from mocks.mock_test_questions
      const { data, error } = await supabase
        .schema('mocks')
        .from('mock_test_questions')
        .select('qid, subject_type, question, option_a, option_b, option_c, option_d, answer_letter')
        .eq('test_id', test.test_id);

      if (error) throw error;
      setTestQuestions(data || []);
    } catch (err: any) {
      console.error('Error fetching test questions:', err);
      // Fallback query to public.app_mock_questions
      try {
        const { data, error } = await supabase
          .from('app_mock_questions')
          .select('question_id, subject, question, option_a, option_b, option_c, option_d, answer')
          .eq('test_id', test.test_id);

        if (!error && data) {
          const mapped = data.map((q: any) => ({
            qid: q.question_id,
            subject_type: q.subject,
            question: q.question,
            option_a: q.option_a,
            option_b: q.option_b,
            option_c: q.option_c,
            option_d: q.option_d,
            answer_letter: q.answer
          }));
          setTestQuestions(mapped);
          return;
        }
      } catch (fallbackErr) {
        console.error('Fallback questions query failed:', fallbackErr);
      }
      alert('Failed to load questions.');
    } finally {
      setLoadingQuestions(false);
    }
  }

  async function handleTogglePublish(testId: string, currentStatus: boolean) {
    if (!window.confirm(`Are you sure you want to ${currentStatus ? 'UNPUBLISH' : 'PUBLISH'} this mock test?`)) return;

    setPublishingTestId(testId);
    try {
      // 1. Update public schema configuration
      const { error: pubErr } = await supabase
        .from('app_mock_tests')
        .update({ published: !currentStatus })
        .eq('test_id', testId);

      if (pubErr) throw pubErr;

      // 2. Update mocks schema configuration
      const { error: mockErr } = await supabase
        .schema('mocks')
        .from('mock_tests')
        .update({ published: !currentStatus })
        .eq('test_id', testId);

      if (mockErr) throw mockErr;

      setTests(tests.map(t => t.test_id === testId ? { ...t, published: !currentStatus } : t));
      alert(`Successfully ${!currentStatus ? 'published' : 'unpublished'} test.`);
    } catch (err: any) {
      console.error(err);
      alert('Failed to toggle publish status: ' + (err.message || String(err)));
    } finally {
      setPublishingTestId(null);
    }
  }

  async function handleDeleteTest(testId: string) {
    if (!window.confirm('Are you absolutely sure you want to delete this test? All questions and CDN payloads will be wiped.')) return;

    setDeletingTestId(testId);
    try {
      // 1. Delete questions from mocks schema
      const { error: delMQErr } = await supabase
        .schema('mocks')
        .from('mock_test_questions')
        .delete()
        .eq('test_id', testId);
      if (delMQErr) throw delMQErr;

      // 2. Delete questions from public schema
      const { error: delPQErr } = await supabase
        .from('app_mock_questions')
        .delete()
        .eq('test_id', testId);
      if (delPQErr) throw delPQErr;

      // 3. Delete results from mocks schema
      try {
        await supabase.schema('mocks').from('mock_results').delete().eq('test_id', testId);
      } catch (err) {}

      // 4. Delete results from public schema
      try {
        await supabase.from('app_mock_results').delete().eq('test_id', testId);
      } catch (err) {}

      // 5. Delete test configs
      const { error: delMTestErr } = await supabase
        .schema('mocks')
        .from('mock_tests')
        .delete()
        .eq('test_id', testId);
      if (delMTestErr) throw delMTestErr;

      const { error: delPTestErr } = await supabase
        .from('app_mock_tests')
        .delete()
        .eq('test_id', testId);
      if (delPTestErr) throw delPTestErr;

      // 6. Delete CDN JSON storage artifact
      try {
        await supabase.storage.from('mock-tests').remove([`test_payloads/${testId}.json`]);
      } catch (err) {}

      setTests(tests.filter(t => t.test_id !== testId));
      alert('Test cascade-deleted successfully.');
    } catch (err: any) {
      console.error(err);
      alert('Failed to delete test: ' + (err.message || String(err)));
    } finally {
      setDeletingTestId(null);
    }
  }

  const getSemestersForCourse = (course: string) => {
    if (course === 'ALL') return [];
    if (course === 'MCA') return [1, 2, 3, 4];
    if (course === 'BCA') return [1, 2, 3, 4, 5, 6];
    return [1, 2, 3, 4, 5, 6, 7, 8];
  };

  const filteredTests = tests.filter(t => {
    if (searchQuery && !t.title.toLowerCase().includes(searchQuery.toLowerCase()) && !t.test_id.toLowerCase().includes(searchQuery.toLowerCase())) return false;
    if (branchFilter !== 'ALL' && t.branch && t.branch !== branchFilter) return false;
    if (courseFilter !== 'ALL' && t.course && t.course !== courseFilter) return false;
    if (semesterFilter !== 'ALL' && t.semester && t.semester.toString() !== semesterFilter) return false;
    return true;
  });

  return (
    <div style={{ maxWidth: 1200, margin: '0 auto', paddingBottom: 100 }}>
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-md)' }}>
          <Link href="/admin/organize" className="btn btn-ghost btn-icon">
            <ArrowLeft size={20} />
          </Link>
          <div>
            <div className="page-title">Manage Mock Tests</div>
            <div className="page-subtitle">Track status, configure states, and cascade deletions</div>
          </div>
        </div>
        <button className="btn btn-ghost" onClick={fetchTests} disabled={loading}>
          <RefreshCw size={18} className={loading ? "spin" : ""} /> Refresh
        </button>
      </div>

      <div className="card animate-fade-in-up" style={{ padding: 'var(--space-md)', marginBottom: 'var(--space-lg)' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-md)', alignItems: 'center', justifyContent: 'space-between' }}>
          <div className="input-group" style={{ flex: '1 1 300px' }}>
            <div className="search-container">
              <Search className="search-icon" size={18} />
              <input 
                type="text" 
                className="input" 
                placeholder="Search title or ID..." 
                value={searchQuery} 
                onChange={e => setSearchQuery(e.target.value)} 
              />
            </div>
          </div>
          <div style={{ display: 'flex', gap: 'var(--space-sm)', flexWrap: 'wrap' }}>
            <select className="input" value={branchFilter} onChange={e => setBranchFilter(e.target.value)}>
              <option value="ALL">ALL Branches</option>
              <option value="Haldwani">Haldwani</option>
              <option value="Bhimtal">Bhimtal</option>
              <option value="Dehradun">Dehradun</option>
            </select>
            <select className="input" value={courseFilter} onChange={e => { setCourseFilter(e.target.value); setSemesterFilter('ALL'); }}>
              <option value="ALL">ALL Courses</option>
              <option value="B.Tech CSE">B.Tech CSE</option>
              <option value="BCA">BCA</option>
              <option value="MCA">MCA</option>
            </select>
            <select className="input" value={semesterFilter} onChange={e => setSemesterFilter(e.target.value)}>
              <option value="ALL">ALL Semesters</option>
              {getSemestersForCourse(courseFilter).map(s => <option key={s} value={String(s)}>Sem {s}</option>)}
            </select>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="skeleton" style={{ height: 200 }} />
      ) : filteredTests.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state-title">No Mock Tests Match Filters</div>
          <div className="empty-state-text">Try adjusting filters or coordinates.</div>
        </div>
      ) : (
        <div className="table-container animate-fade-in-up">
          <table className="table">
            <thead>
              <tr>
                <th>Title</th>
                <th>Target coordinates</th>
                <th>Question count</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredTests.map(t => (
                <tr key={t.test_id}>
                  <td style={{ fontWeight: 500 }}>
                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                      <span>{t.title}</span>
                      <span style={{ fontSize: '10px', color: 'var(--color-text-muted)'}}>{t.test_id}</span>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                      <span className="badge" style={{ background: 'var(--color-bg-hover)', color: 'var(--color-text)', fontSize: '10px' }}>
                        {t.branch || 'ALL'}
                      </span>
                      <span className="badge" style={{ background: 'var(--color-bg-hover)', color: 'var(--color-text)', fontSize: '10px' }}>
                        {t.course || 'ALL'}
                      </span>
                      <span className="badge" style={{ background: 'var(--color-bg-hover)', color: 'var(--color-text)', fontSize: '10px' }}>
                        Sem {t.semester || 'ALL'}
                      </span>
                    </div>
                  </td>
                  <td>{t.total_questions || '0'} Qs</td>
                  <td>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'flex-start' }}>
                      {!t.published ? (
                        <span className="badge" style={{ background: 'transparent', color: '#9ca3af', border: '1px solid #9ca3af', fontWeight: 600 }}>Draft</span>
                      ) : (() => {
                        const start = t.start_at ? new Date(t.start_at).getTime() : 0;
                        const end = t.exam_end_at ? new Date(t.exam_end_at).getTime() : (start + (t.duration_minutes || 60) * 60000);
                        const currentTime = now.getTime();
                        
                        if (currentTime > end) {
                          return <span className="badge" style={{ background: 'rgba(156, 163, 175, 0.15)', color: '#9ca3af', fontWeight: 600 }}>Ended</span>;
                        } else if (currentTime >= start && currentTime <= end) {
                          return <span className="badge" style={{ background: 'rgba(16, 185, 129, 0.15)', color: '#10b981', fontWeight: 600 }}>Live Now</span>;
                        } else {
                          return <span className="badge" style={{ background: 'rgba(245, 158, 11, 0.15)', color: '#f59e0b', fontWeight: 600 }}>Upcoming</span>;
                        }
                      })()}
                      
                      {t.requires_web_proctoring && (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 2, alignItems: 'flex-start' }}>
                          <span className="badge" style={{ background: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6', fontSize: '9px', display: 'flex', alignItems: 'center', gap: 4 }}>
                            <Monitor size={10} /> PC Only
                          </span>
                          <span style={{ fontSize: '9px', color: 'var(--color-text-muted)', fontWeight: 600, paddingLeft: 4, display: 'flex', alignItems: 'center', gap: 4 }}>
                            👤 Verified: {t.fully_ready_students || 0}/{t.total_verified_students || 0} Ready
                          </span>
                        </div>
                      )}
                      {t.results_published && (
                        <span className="badge" style={{ background: 'rgba(139, 92, 246, 0.1)', color: '#8b5cf6', fontSize: '9px', display: 'flex', alignItems: 'center', gap: 4 }}>
                          <BarChart size={10} /> Results Released
                        </span>
                      )}
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <button className="btn btn-sm btn-ghost btn-icon" title="View questions list preview" onClick={() => fetchQuestionsForTest(t)}>
                        <BookOpen size={15} color="#3b82f6" />
                      </button>
                      <button className="btn btn-sm btn-ghost btn-icon" title="Toggle publish status" onClick={() => handleTogglePublish(t.test_id, t.published)} disabled={publishingTestId === t.test_id}>
                        {t.published ? <EyeOff size={15} color="#9ca3af" /> : <Eye size={15} color="#10b981" />}
                      </button>
                      <button className="btn btn-sm btn-ghost btn-icon" title="View report dashboard analytics" onClick={() => router.push(`/admin/reports?test=${t.test_id}`)}>
                        <BarChart size={15} color="#f59e0b" />
                      </button>
                      <button className="btn btn-sm btn-ghost btn-icon" title="Cascade delete test" onClick={() => handleDeleteTest(t.test_id)} disabled={deletingTestId !== null}>
                        <Trash2 size={15} color="#ef4444" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {selectedQuestionsTest && (
        <div className="modal-overlay" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(4px)' }}>
          <div className="modal-content" style={{ maxWidth: 850, width: '90%', maxHeight: '90vh', overflowY: 'auto', borderRadius: '12px', background: 'var(--color-bg-surface)', padding: 'var(--space-xl)', border: '1px solid var(--color-border)', boxShadow: 'var(--shadow-xl)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-md)', borderBottom: '1px solid var(--color-border)', paddingBottom: 'var(--space-sm)' }}>
              <h2 style={{ fontSize: 'var(--font-size-xl)', display: 'flex', alignItems: 'center', gap: 10, margin: 0, fontWeight: 700 }}>
                <ClipboardList size={24} color="var(--color-accent)" /> Questions List Preview
              </h2>
              <button className="btn btn-ghost btn-icon" onClick={() => setSelectedQuestionsTest(null)}>
                <X size={20} />
              </button>
            </div>
            {loadingQuestions ? (
              <div style={{ textAlign: 'center', padding: 40, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
                <Loader2 className="spin" size={24} />
                <span>Loading question details...</span>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
                {testQuestions.map((q, idx) => {
                  const subType = q.subject_type || q.subject || 'APTITUDE';
                  const answerLetter = q.answer_letter || q.answer || 'A';
                  return (
                    <div key={q.qid || idx} style={{ background: 'var(--color-bg-hover)', padding: 'var(--space-md)', borderRadius: 8, borderLeft: `4px solid ${subType.toUpperCase() === 'APTITUDE' ? '#3b82f6' : '#ec4899'}` }}>
                      <div style={{ fontWeight: 700, marginBottom: 10 }}>Q{idx + 1}. {q.question}</div>
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-sm)' }}>
                        {['a', 'b', 'c', 'd'].map(optKey => {
                          const isCorrect = answerLetter.toUpperCase() === optKey.toUpperCase();
                          // Retrieve Option Content Dynamically
                          const optText = (q as any)[`option_${optKey}`];
                          return (
                            <div key={optKey} style={{ 
                              padding: '8px 12px', 
                              borderRadius: 6, 
                              background: isCorrect ? 'rgba(16, 185, 129, 0.12)' : 'var(--color-bg-surface)', 
                              border: `1px solid ${isCorrect ? '#10b981' : 'var(--color-border)'}`, 
                              color: isCorrect ? '#10b981' : 'var(--color-text)', 
                              fontSize: 'var(--font-size-xs)' 
                            }}>
                              <span style={{ opacity: 0.6 }}>{optKey.toUpperCase()}.</span> {optText}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 'var(--space-md)' }}>
              <button className="btn btn-primary" onClick={() => setSelectedQuestionsTest(null)}>Close Preview</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
