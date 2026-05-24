"use client";

import React, { useState, useEffect, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '../../../../providers/AuthProvider';
import { supabase } from '../../../../../utils/supabaseClient';
import { 
  Award, Play, Clock, HelpCircle, ArrowLeft, ArrowRight, 
  CheckSquare, AlertCircle, ShieldAlert, Monitor, Check, RefreshCw 
} from 'lucide-react';

interface QuestionItem {
  qid: string;
  question: string;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  subject: string;
  subject_type: string;
  q_index: number;
}

interface TestHeaderItem {
  test_id: string;
  title: string;
  duration_minutes: number;
  marking_aptitude_per_q: number;
  marking_english_per_q: number;
  negative_enabled: boolean;
  negative_value: number;
  start_at: string;
}

export default function MockTestRunnerPage() {
  const params = useParams();
  const router = useRouter();
  const testId = params?.testId as string;
  const { identity, loading: authLoading } = useAuth();

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [test, setTest] = useState<TestHeaderItem | null>(null);
  const [questions, setQuestions] = useState<QuestionItem[]>([]);
  
  const [currentIdx, setCurrentIdx] = useState(0);
  const [optMap, setOptMap] = useState<Record<string, string>>({});
  const [warnCount, setWarnCount] = useState(0);
  
  // Timer States
  const [secondsRemaining, setSecondsRemaining] = useState<number>(0);
  const startedAtRef = useRef<string>(new Date().toISOString());

  // Prevent multiple submits
  const isSubmittedRef = useRef(false);

  useEffect(() => {
    if (!authLoading && testId) {
      loadExamEnvironment();
    }
  }, [authLoading, testId]);

  // Real-time ticking effect
  useEffect(() => {
    if (loading || secondsRemaining <= 0 || isSubmittedRef.current) return;

    const timer = setInterval(() => {
      setSecondsRemaining(prev => {
        if (prev <= 1) {
          clearInterval(timer);
          triggerAutoSubmit(warnCount);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [loading, secondsRemaining]);

  // Anti-Cheat Visibility API Guard
  useEffect(() => {
    if (loading || isSubmittedRef.current) return;

    const handleVisibilityChange = () => {
      if (document.hidden) {
        setWarnCount(w => {
          const next = w + 1;
          if (next >= 3) {
            triggerAutoSubmit(next);
          } else {
            alert(`PROCTORING SECURITY ALERT: Leaving the examination screen is strictly prohibited! Warning ${next}/3. Next violation will automatically submit your exam.`);
          }
          return next;
        });
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => document.removeEventListener('visibilitychange', handleVisibilityChange);
  }, [loading, warnCount, optMap]);

  async function loadExamEnvironment() {
    try {
      setLoading(true);

      // 1. Fetch test header
      const { data: headerData, error: headerError } = await supabase
        .schema('mocks')
        .from('mock_tests')
        .select('test_id, title, duration_minutes, marking_aptitude_per_q, marking_english_per_q, negative_enabled, negative_value, start_at')
        .eq('test_id', testId)
        .single();

      if (headerError || !headerData) throw new Error('Test information is currently unavailable.');
      
      setTest(headerData);

      // 2. Check if student has already submitted results to avoid re-entry
      const { data: existingResult } = await supabase
        .schema('mocks')
        .from('mock_results')
        .select('submitted_at, locked')
        .eq('test_id', testId)
        .maybeSingle();

      if (existingResult?.locked || existingResult?.submitted_at) {
        alert('You have already submitted this examination!');
        router.push('/student/mock-tests');
        return;
      }

      // 3. Fetch questions list
      const { data: questionsData, error: questionsError } = await supabase
        .schema('mocks')
        .from('mock_test_questions')
        .select('qid, question, option_a, option_b, option_c, option_d, subject, subject_type, q_index')
        .eq('test_id', testId)
        .order('q_index', { ascending: true });

      if (questionsError || !questionsData || questionsData.length === 0) {
        throw new Error('This exam does not have any active questions populated yet.');
      }

      setQuestions(questionsData);
      setSecondsRemaining(headerData.duration_minutes * 60);
      startedAtRef.current = new Date().toISOString();
    } catch (err: any) {
      console.error('Error loading exam env:', err);
      alert(err.message || String(err));
      router.push('/student/mock-tests');
    } finally {
      setLoading(false);
    }
  }

  async function triggerAutoSubmit(activeWarns: number) {
    if (isSubmittedRef.current) return;
    isSubmittedRef.current = true;
    
    setSubmitting(true);
    alert('Security Violation or Timer Expiration reached. Automatically submitting your answers now...');

    try {
      const qOrder = questions.map(q => q.qid);
      const { data, error } = await supabase
        .schema('mocks')
        .rpc('api_student_submit_mock_result', {
          p_test_id: testId,
          p_q_order: qOrder,
          p_opt_map: optMap,
          p_warn_count: activeWarns,
          p_started_at: startedAtRef.current,
          p_session_end_time: new Date().toISOString()
        });

      if (error) throw error;
      
      router.push('/student/results');
    } catch (err: any) {
      console.error('Error auto submitting:', err);
      alert('Failed to submit exam: ' + (err.message || String(err)));
      isSubmittedRef.current = false;
      router.push('/student/mock-tests');
    } finally {
      setSubmitting(false);
    }
  }

  async function handleFinalSubmit() {
    if (isSubmittedRef.current) return;

    const unattempted = questions.length - Object.keys(optMap).length;
    let confirmMsg = 'Are you sure you want to finish the exam and submit your answers?';
    if (unattempted > 0) {
      confirmMsg = `You have ${unattempted} unattempted questions remaining. Are you sure you want to submit?`;
    }

    if (!window.confirm(confirmMsg)) return;

    isSubmittedRef.current = true;
    setSubmitting(true);

    try {
      const qOrder = questions.map(q => q.qid);
      const { data, error } = await supabase
        .schema('mocks')
        .rpc('api_student_submit_mock_result', {
          p_test_id: testId,
          p_q_order: qOrder,
          p_opt_map: optMap,
          p_warn_count: warnCount,
          p_started_at: startedAtRef.current,
          p_session_end_time: new Date().toISOString()
        });

      if (error) throw error;

      alert('Exam submitted successfully!');
      router.push('/student/results');
    } catch (err: any) {
      console.error('Error submitting mock results:', err);
      alert('Failed to submit exam: ' + (err.message || String(err)));
      isSubmittedRef.current = false;
    } finally {
      setSubmitting(false);
    }
  }

  const formatTimer = (totalSeconds: number) => {
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  };

  const handleSelectOption = (letter: string) => {
    const activeQ = questions[currentIdx];
    setOptMap(prev => ({
      ...prev,
      [activeQ.qid]: letter
    }));
  };

  const handleClearAnswer = () => {
    const activeQ = questions[currentIdx];
    setOptMap(prev => {
      const copy = { ...prev };
      delete copy[activeQ.qid];
      return copy;
    });
  };

  if (loading || authLoading) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 16 }}>
        <RefreshCw className="spin" size={36} style={{ color: 'var(--color-accent)' }} />
        <div style={{ fontSize: 'var(--font-size-lg)', color: 'var(--color-text-secondary)', fontWeight: 600 }}>Hydrating secure exam environment...</div>
      </div>
    );
  }

  if (submitting) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', gap: 16 }}>
        <RefreshCw className="spin" size={36} style={{ color: 'var(--color-error)' }} />
        <div style={{ fontSize: 'var(--font-size-lg)', color: 'var(--color-text-primary)', fontWeight: 600 }}>Securing and evaluating your answers...</div>
      </div>
    );
  }

  const activeQuestion = questions[currentIdx];
  const selectedOption = optMap[activeQuestion.qid] || '';

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '280px 1fr', gap: 'var(--space-lg)', maxWidth: 1200, margin: '0 auto', paddingBottom: 60 }} className="animate-fade-in">
      {/* Sidebar Question Grid */}
      <div className="card flex flex-col gap-md" style={{ height: 'fit-content' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 className="section-title" style={{ margin: 0 }}>Progress</h3>
          <span className="badge badge-accent" style={{ fontSize: 10 }}>{Object.keys(optMap).length} / {questions.length}</span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 8, maxHeight: 300, overflowY: 'auto', padding: 2 }}>
          {questions.map((q, idx) => {
            const isSelected = idx === currentIdx;
            const isAttempted = !!optMap[q.qid];

            return (
              <button
                key={q.qid}
                style={{
                  width: '100%',
                  aspectRatio: '1',
                  borderRadius: 'var(--radius-sm)',
                  fontSize: 'var(--font-size-xs)',
                  fontWeight: 700,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  border: isSelected ? '2px solid var(--color-accent)' : '1px solid var(--color-border)',
                  background: isSelected ? 'var(--color-accent-subtle)' :
                              isAttempted ? 'rgba(34, 211, 238, 0.15)' : 'transparent',
                  color: isSelected ? 'var(--color-accent)' :
                         isAttempted ? '#22d3ee' : 'var(--color-text-secondary)'
                }}
                onClick={() => setCurrentIdx(idx)}
              >
                {idx + 1}
              </button>
            );
          })}
        </div>

        <div style={{ borderTop: '1px solid var(--color-border)', paddingTop: 'var(--space-md)', display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div className="flex items-center gap-sm" style={{ fontSize: 11, color: 'var(--color-text-muted)', fontWeight: 500 }}>
            <span style={{ width: 12, height: 12, background: 'rgba(34, 211, 238, 0.15)', borderRadius: 'var(--radius-sm)' }}></span> Attempted
          </div>
          <div className="flex items-center gap-sm" style={{ fontSize: 11, color: 'var(--color-text-muted)', fontWeight: 500 }}>
            <span style={{ width: 12, height: 12, background: 'transparent', border: '1px solid var(--color-border)', borderRadius: 'var(--radius-sm)' }}></span> Unattempted
          </div>
          {warnCount > 0 && (
            <div className="flex items-center gap-sm" style={{ fontSize: 11, color: 'var(--color-error)', fontWeight: 600, marginTop: 4 }}>
              <ShieldAlert size={12} /> Proctor Warnings: {warnCount}/3
            </div>
          )}
        </div>
      </div>

      {/* Primary Runner Area */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
        {/* Runner Header */}
        <div className="card flex items-center justify-between" style={{ padding: 'var(--space-md) var(--space-lg)' }}>
          <div>
            <h2 className="card-title" style={{ fontSize: 'var(--font-size-lg)' }}>{test?.title}</h2>
            <div className="card-subtitle" style={{ fontSize: 'var(--font-size-xs)', display: 'flex', gap: 12 }}>
              <span>Category: {activeQuestion.subject_type || 'APTITUDE'}</span>
              <span>Marking: +{activeQuestion.subject_type === 'APTITUDE' ? test?.marking_aptitude_per_q : test?.marking_english_per_q} / -{test?.negative_enabled ? test.negative_value : 0}</span>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div className="badge badge-accent" style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 12px', fontSize: 'var(--font-size-sm)' }}>
              <Clock size={14} /> {formatTimer(secondsRemaining)}
            </div>
          </div>
        </div>

        {/* Current Question Frame */}
        <div className="card flex flex-col gap-lg" style={{ minHeight: 320 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <span className="badge badge-info">{activeQuestion.subject}</span>
            <span style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)', fontWeight: 600 }}>Question {currentIdx + 1} of {questions.length}</span>
          </div>

          <div style={{ fontSize: 'var(--font-size-lg)', fontWeight: 600, color: 'var(--color-text-primary)', borderBottom: '1px solid var(--color-border)', paddingBottom: 'var(--space-md)' }}>
            {activeQuestion.question}
          </div>

          {/* Custom radio buttons */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-sm)' }}>
            {[
              { key: 'A', text: activeQuestion.option_a },
              { key: 'B', text: activeQuestion.option_b },
              { key: 'C', text: activeQuestion.option_c },
              { key: 'D', text: activeQuestion.option_d }
            ].map(o => {
              const isSelected = selectedOption === o.key;

              return (
                <button
                  key={o.key}
                  style={{
                    width: '100%',
                    padding: 'var(--space-md)',
                    borderRadius: 'var(--radius-md)',
                    textAlign: 'left',
                    fontSize: 'var(--font-size-base)',
                    fontWeight: 500,
                    border: isSelected ? '1px solid var(--color-accent)' : '1px solid var(--color-border)',
                    background: isSelected ? 'var(--color-accent-subtle)' : 'var(--color-bg-input)',
                    color: isSelected ? 'var(--color-accent)' : 'var(--color-text-primary)',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 'var(--space-md)',
                    transition: 'all var(--transition-fast)'
                  }}
                  onClick={() => handleSelectOption(o.key)}
                >
                  <span
                    style={{
                      width: 20,
                      height: 20,
                      borderRadius: 'var(--radius-full)',
                      border: isSelected ? '6px solid var(--color-accent)' : '2px solid var(--color-text-muted)',
                      background: 'transparent',
                      transition: 'all var(--transition-fast)'
                    }}
                  />
                  <span>{o.text}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Footer Actions */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
            <button 
              className="btn btn-secondary"
              disabled={currentIdx === 0}
              onClick={() => setCurrentIdx(prev => prev - 1)}
            >
              <ArrowLeft size={16} /> Previous
            </button>
            <button 
              className="btn btn-secondary"
              disabled={currentIdx === questions.length - 1}
              onClick={() => setCurrentIdx(prev => prev + 1)}
            >
              Next <ArrowRight size={16} />
            </button>
          </div>

          <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
            {selectedOption && (
              <button className="btn btn-ghost" onClick={handleClearAnswer}>
                Clear Choice
              </button>
            )}
            <button className="btn btn-primary" onClick={handleFinalSubmit}>
              <CheckSquare size={16} /> Submit Exam
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
