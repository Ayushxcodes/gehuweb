"use client";

import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { supabase } from '../../../../utils/supabaseClient';
import { ClipboardList, ArrowLeft, Loader2, Plus, X, Check, RefreshCw } from 'lucide-react';

interface ManualTestConfig {
  isMainExam: boolean;
  title: string;
  branch: string;
  course: string;
  semester: string;
  startDate: string;
  startTime: string;
  duration: number | '';
  marksAptitude: number | '';
  marksEnglish: number | '';
  negativeEnabled: boolean;
  negativeValueAptitude: number | '';
  negativeValueEnglish: number | '';
  negativeApplyAptitude: boolean;
  negativeApplyEnglish: boolean;
  splitA: number | '';
  splitE: number | '';
  totalQuestions: number | '';
}

export default function CreateManualMockPage() {
  const router = useRouter();

  const [creating, setCreating] = useState(false);

  // Form State
  const [newTest, setNewTest] = useState<ManualTestConfig>({
    isMainExam: false,
    title: '',
    branch: 'ALL',
    course: 'ALL',
    semester: 'ALL',
    startDate: '',
    startTime: '',
    duration: 60,
    marksAptitude: 1,
    marksEnglish: 2,
    negativeEnabled: false,
    negativeValueAptitude: 0.25,
    negativeValueEnglish: 0.25,
    negativeApplyAptitude: true,
    negativeApplyEnglish: true,
    splitA: 10,
    splitE: 10,
    totalQuestions: 20,
  });

  const [selectedAptTopics, setSelectedAptTopics] = useState<string[]>([]);
  const [selectedEngTopics, setSelectedEngTopics] = useState<string[]>([]);
  const topicBankQuery = useQuery({
    queryKey: ['admin-manual-mock-topic-bank'],
    queryFn: async ({ signal }) => {
      const apt = new Set<string>();
      const eng = new Set<string>();
      const counts: Record<string, number> = {};

      const { data: practiceData, error: practiceErr } = await supabase
        .from('practice_question_bank')
        .select('subject, topic')
        .abortSignal(signal);

      if (practiceErr) throw practiceErr;

      (practiceData || []).forEach((q: any) => {
        if (!q.topic) return;
        const cleanSubj = (q.subject || '').toUpperCase();
        const topic = q.topic;
        counts[topic] = (counts[topic] || 0) + 1;

        if (cleanSubj.includes('APTITUDE') || cleanSubj.includes('MATH') || cleanSubj.includes('LOGIC')) {
          apt.add(topic);
        } else {
          eng.add(topic);
        }
      });

      if (apt.size === 0) {
        ['Quantitative Aptitude', 'Logical Reasoning', 'Data Interpretation', 'Puzzles'].forEach(t => {
          apt.add(t);
          counts[t] = 0;
        });
      }

      if (eng.size === 0) {
        ['Reading Comprehension', 'Sentence Correction', 'Vocabulary', 'Grammar Rules'].forEach(t => {
          eng.add(t);
          counts[t] = 0;
        });
      }

      return {
        aptitudeTopics: Array.from(apt).sort(),
        englishTopics: Array.from(eng).sort(),
        counts,
      };
    },
  });

  const dbAptitudeTopics = topicBankQuery.data?.aptitudeTopics || [];
  const dbEnglishTopics = topicBankQuery.data?.englishTopics || [];
  const topicCounts = topicBankQuery.data?.counts || {};
  const loadingTopics = topicBankQuery.isPending && !topicBankQuery.data;
  const refreshingTopics = topicBankQuery.isFetching && !!topicBankQuery.data;

  const numericValue = (value: number | '') => (value === '' ? 0 : value);

  // Sync state between total questions and splits
  const handleTotalQuestionsChange = (total: number) => {
    const T = Math.max(0, total);
    setNewTest(prev => {
      let A = numericValue(prev.splitA);
      let E = numericValue(prev.splitE);

      if ((A > 0 && E > 0) || (A === 0 && E === 0)) {
        A = Math.floor(T / 2);
        E = T - A;
      } else if (A > 0) {
        A = T;
        E = 0;
      } else if (E > 0) {
        E = T;
        A = 0;
      }

      return { ...prev, totalQuestions: T, splitA: A, splitE: E };
    });
  };

  const handleSplitAChange = (val: number) => {
    const A = Math.max(0, val);
    setNewTest(prev => {
      const T = numericValue(prev.totalQuestions);
      const E = Math.max(0, T - A);
      return { ...prev, splitA: A, splitE: E };
    });
  };

  const handleSplitEChange = (val: number) => {
    const E = Math.max(0, val);
    setNewTest(prev => {
      const T = numericValue(prev.totalQuestions);
      const A = Math.max(0, T - E);
      return { ...prev, splitA: A, splitE: E };
    });
  };

  const getSemestersForCourse = (course: string) => {
    if (course === 'ALL') return [];
    if (course === 'MCA') return [1, 2, 3, 4];
    if (course === 'BCA') return [1, 2, 3, 4, 5, 6];
    return [1, 2, 3, 4, 5, 6, 7, 8];
  };

  const shuffleArray = (array: any[]) => {
    const arr = [...array];
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
  };

  // Maps custom schema fields cleanly to uniform entities
  const mapToStandardQuestion = (q: any, index: number) => {
    const cleanQuestion = q.question || q.question_text || '';
    const cleanAnswer = q.answer_letter || q.answer_key || q.answer || 'A';
    return {
      qid: q.qid || q.question_id || `q_${index}_${Date.now()}`,
      subject_type: q.subject_type || (q.subject && q.subject.toUpperCase().includes('ENG') ? 'ENGLISH' : 'APTITUDE'),
      topic: q.topic || 'General',
      question: cleanQuestion,
      option_a: q.option_a || '',
      option_b: q.option_b || '',
      option_c: q.option_c || '',
      option_d: q.option_d || '',
      answer_letter: cleanAnswer.toUpperCase().trim(),
      solution: q.solution || '',
      difficulty: q.difficulty || 'medium',
      active: true,
      source: 'manual'
    };
  };

  async function handleCreateTest(e: React.FormEvent) {
    e.preventDefault();
    if (!newTest.startDate || !newTest.startTime) {
      return alert("Please select a valid start date and start time.");
    }
    const checkDateTime = new Date(`${newTest.startDate}T${newTest.startTime}:00`);
    if (isNaN(checkDateTime.getTime())) {
      return alert("The selected start date or time is invalid.");
    }
    if (checkDateTime < new Date()) {
      return alert("The start time must be scheduled in the future.");
    }

    if (Number(newTest.splitA) + Number(newTest.splitE) === 0) {
      return alert("You must include at least one question limit (Aptitude or English).");
    }
    if (Number(newTest.splitA) > 0 && selectedAptTopics.length === 0) {
      return alert("You requested Aptitude questions but selected no Aptitude topics.");
    }
    if (Number(newTest.splitE) > 0 && selectedEngTopics.length === 0) {
      return alert("You requested English questions but selected no English topics.");
    }

    setCreating(true);
    try {
      let candidateApt: any[] = [];
      let candidateEng: any[] = [];

      // Resilient Fetch 1: Fetch Aptitude candidates
      if (Number(newTest.splitA) > 0) {
        // Try practice bank
        const { data: aptP, error: aptPErr } = await supabase
          .from('practice_question_bank')
          .select('*')
          .in('topic', selectedAptTopics);

        if (!aptPErr && aptP) {
          candidateApt = [...candidateApt, ...aptP];
        }

        // Try mocks schema
        try {
          const { data: aptM, error: aptMErr } = await supabase
            .schema('mocks')
            .from('mock_test_questions')
            .select('*')
            .eq('subject_type', 'APTITUDE')
            .in('topic', selectedAptTopics);

          if (!aptMErr && aptM) {
            candidateApt = [...candidateApt, ...aptM];
          }
        } catch (e) {}
      }

      // Resilient Fetch 2: Fetch English candidates
      if (Number(newTest.splitE) > 0) {
        // Try practice bank
        const { data: engP, error: engPErr } = await supabase
          .from('practice_question_bank')
          .select('*')
          .in('topic', selectedEngTopics);

        if (!engPErr && engP) {
          candidateEng = [...candidateEng, ...engP];
        }

        // Try mocks schema
        try {
          const { data: engM, error: engMErr } = await supabase
            .schema('mocks')
            .from('mock_test_questions')
            .select('*')
            .eq('subject_type', 'ENGLISH')
            .in('topic', selectedEngTopics);

          if (!engMErr && engM) {
            candidateEng = [...candidateEng, ...engM];
          }
        } catch (e) {}
      }

      // Filter local duplicates if any question overlaps
      const seenIds = new Set<string>();
      const aptPool: any[] = [];
      candidateApt.forEach(q => {
        const id = q.question_id || q.qid;
        if (!id || seenIds.has(id)) return;
        seenIds.add(id);
        aptPool.push(q);
      });

      const engPool: any[] = [];
      candidateEng.forEach(q => {
        const id = q.question_id || q.qid;
        if (!id || seenIds.has(id)) return;
        seenIds.add(id);
        engPool.push(q);
      });

      // Shuffling
      const finalAptSelected = shuffleArray(aptPool).slice(0, numericValue(newTest.splitA));
      const finalEngSelected = shuffleArray(engPool).slice(0, numericValue(newTest.splitE));

      const rawCombined = [...finalAptSelected, ...finalEngSelected];

      if (rawCombined.length === 0) {
        throw new Error("No matching questions found in the database. Please add questions to the practice bank first.");
      }

      const mappedQuestions = rawCombined.map((q, idx) => mapToStandardQuestion(q, idx));

      const negativeApplyTo: string[] = [];
      if (newTest.negativeEnabled) {
        if (newTest.negativeApplyAptitude) negativeApplyTo.push('Aptitude');
        if (newTest.negativeApplyEnglish) negativeApplyTo.push('English');
      }

      // Date / Time processing
      const combinedDateTimeStr = `${newTest.startDate}T${newTest.startTime}:00`;
      const combinedDateTime = new Date(combinedDateTimeStr);
      const nowIso = new Date().toISOString();
      const examEnd = new Date(combinedDateTime);
      const durationVal = typeof newTest.duration === 'string' ? 0 : newTest.duration;
      examEnd.setMinutes(examEnd.getMinutes() + durationVal);
      const expires = new Date(examEnd);
      expires.setDate(expires.getDate() + 7);

      const generateUUID = () => {
        if (typeof window !== 'undefined' && window.crypto && window.crypto.randomUUID) {
          return window.crypto.randomUUID();
        }
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
          const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
          return v.toString(16);
        });
      };

      const testId = generateUUID();
      const frozenIds = mappedQuestions.map((_, idx) => `${testId}_q${idx}`);

      // 1. Build & Sync CDN Storage Payload for Android clients
      const fileBuffer = new Blob([JSON.stringify(mappedQuestions)], { type: 'application/json' });
      const filePath = `test_payloads/${testId}.json`;

      const { error: storageError } = await supabase.storage
        .from('mock-tests')
        .upload(filePath, fileBuffer, {
          contentType: 'application/json',
          upsert: true
        });

      if (storageError) {
        console.warn("Storage upload failed:", storageError);
      }

      const { data: publicUrlData } = supabase.storage.from('mock-tests').getPublicUrl(filePath);
      const cdnUrl = publicUrlData?.publicUrl || '';

      // 2. Insert to public.app_mock_tests
      const { error: pubTestErr } = await supabase
        .from('app_mock_tests')
        .insert([{
          test_id: testId,
          title: newTest.title.trim(),
          duration_minutes: newTest.duration === '' ? 0 : newTest.duration,
          requires_web_proctoring: newTest.isMainExam,
          payload_cdn_url: cdnUrl,
          start_at: combinedDateTime.toISOString(),
          created_at: nowIso
        }]);
      if (pubTestErr) throw pubTestErr;

      // 3. Insert to mocks.mock_tests with extra campus targeting
      const { error: mockTestErr } = await supabase
        .schema('mocks')
        .from('mock_tests')
        .insert([{
          test_id: testId,
          title: newTest.title.trim(),
          branch: newTest.branch === 'ALL' ? 'ALL' : newTest.branch,
          course: newTest.course === 'ALL' ? 'ALL' : newTest.course,
          semester: newTest.semester === 'ALL' ? 'ALL' : String(parseInt(newTest.semester, 10)),
          total_questions: mappedQuestions.length,
          duration_minutes: newTest.duration === '' ? 0 : newTest.duration,
          start_at: combinedDateTime.toISOString(),
          scheduled_start_at: combinedDateTime.toISOString(),
          exam_end_at: examEnd.toISOString(),
          expires_at: expires.toISOString(),
          status: 'POSTED',
          source: 'manual',
          marking_aptitude_per_q: newTest.marksAptitude === '' ? 0 : newTest.marksAptitude,
          marking_english_per_q: newTest.marksEnglish === '' ? 0 : newTest.marksEnglish,
          negative_enabled: newTest.negativeEnabled,
          negative_value: newTest.negativeEnabled ? (newTest.negativeValueAptitude === '' ? 0.0 : newTest.negativeValueAptitude) : 0.0,
          negative_value_aptitude: newTest.negativeEnabled ? (newTest.negativeValueAptitude === '' ? 0.0 : newTest.negativeValueAptitude) : 0.0,
          negative_value_english: newTest.negativeEnabled ? (newTest.negativeValueEnglish === '' ? 0.0 : newTest.negativeValueEnglish) : 0.0,
          negative_apply_to: negativeApplyTo.length ? negativeApplyTo : [],
          requires_web_proctoring: newTest.isMainExam,
          frozen_ids: frozenIds,
          published: true,
          results_published: false
        }]);
      if (mockTestErr) throw mockTestErr;

      // 4. Batch-insert to public.app_mock_questions
      const publicQuestionRows = mappedQuestions.map((q) => ({
        question_id: generateUUID(),
        test_id: testId,
        subject: q.subject_type,
        topic: q.topic,
        question: q.question,
        option_a: q.option_a,
        option_b: q.option_b,
        option_c: q.option_c,
        option_d: q.option_d,
        answer: q.answer_letter,
        difficulty: q.difficulty,
        solution: q.solution
      }));

      const { error: pubQuestErr } = await supabase
        .from('app_mock_questions')
        .insert(publicQuestionRows);
      if (pubQuestErr) throw pubQuestErr;

      // 5. Batch-insert to mocks.mock_test_questions
      const mockQuestionRows = mappedQuestions.map((q, idx) => ({
        test_id: testId,
        qid: `${testId}_q${idx}`,
        q_index: idx,
        subject: q.subject_type,
        subject_type: q.subject_type,
        question: q.question,
        option_a: q.option_a,
        option_b: q.option_b,
        option_c: q.option_c,
        option_d: q.option_d,
        answer_letter: q.answer_letter,
        solution_mode: 'full',
        solution: q.solution,
        difficulty: q.difficulty,
        active: true,
        source: 'manual',
        uploaded_at: nowIso
      }));

      const { error: mockQuestErr } = await supabase
        .schema('mocks')
        .from('mock_test_questions')
        .insert(mockQuestionRows);
      if (mockQuestErr) throw mockQuestErr;

      alert(`Success! Created manual mock test: "${newTest.title}"`);
      router.push('/admin/mock-tests/manage');

    } catch (err: any) {
      console.error(err);
      alert('Error creating manual test: ' + (err.message || String(err)));
    } finally {
      setCreating(false);
    }
  }

  const handleToggleTopic = (subject: 'APT' | 'ENG', topic: string) => {
    if (subject === 'APT') {
      setSelectedAptTopics(prev => prev.includes(topic) ? prev.filter(t => t !== topic) : [...prev, topic]);
    } else {
      setSelectedEngTopics(prev => prev.includes(topic) ? prev.filter(t => t !== topic) : [...prev, topic]);
    }
  };

  return (
    <div style={{ maxWidth: 850, margin: '0 auto', paddingBottom: 100 }}>
      <div className="page-header" style={{ marginBottom: 'var(--space-md)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-md)' }}>
          <Link href="/admin/organize" className="btn btn-ghost btn-icon">
            <ArrowLeft size={20} />
          </Link>
          <div>
            <div className="page-title">Generate Manual Mock Test</div>
            <div className="page-subtitle">Assemble examinations using relational question bank pools</div>
          </div>
        </div>
      </div>

      <form onSubmit={handleCreateTest} className="animate-fade-in-up">
        <style>{`
          /* Hide number input spinners */
          input::-webkit-outer-spin-button,
          input::-webkit-inner-spin-button {
            -webkit-appearance: none;
            margin: 0;
          }
          input[type=number] {
            -moz-appearance: textfield;
          }

          /* Make date/time inputs click anywhere to open calendar/picker */
          input[type="date"], input[type="time"] {
            position: relative;
            cursor: pointer;
          }
          input[type="date"]::-webkit-calendar-picker-indicator,
          input[type="time"]::-webkit-calendar-picker-indicator {
            background: transparent;
            bottom: 0;
            color: transparent;
            cursor: pointer;
            height: auto;
            left: 0;
            position: absolute;
            right: 0;
            top: 0;
            width: auto;
          }
        `}</style>

        {/* WEBCAM PROCTORING CONFIG */}
        <div className="card" style={{
          background: newTest.isMainExam ? 'rgba(239, 68, 68, 0.08)' : 'var(--color-bg-surface)',
          padding: 'var(--space-md)',
          borderRadius: 8,
          marginBottom: 'var(--space-lg)',
          borderLeft: newTest.isMainExam ? '4px solid var(--color-error)' : '4px solid var(--color-border)',
          transition: 'all 0.2s ease'
        }}>
          <label style={{ display: 'flex', alignItems: 'flex-start', gap: 12, cursor: 'pointer' }}>
            <input
              type="checkbox"
              checked={newTest.isMainExam}
              onChange={e => setNewTest({...newTest, isMainExam: e.target.checked})}
              style={{ marginTop: 4, transform: 'scale(1.1)' }}
              disabled={creating}
            />
            <div>
              <div style={{ fontWeight: 700, color: newTest.isMainExam ? 'var(--color-error)' : 'var(--color-text)' }}>
                Enforce Camera Proctoring & Browser Lockdown (Main Exam)
              </div>
              <div style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)', marginTop: 4 }}>
                Requires students to grant camera permissions. Detects page exits, copy-paste shortcuts, and logs security alerts during attempt.
              </div>
            </div>
          </label>
        </div>

        {/* BASIC IDENTIFICATION */}
        <div className="card" style={{ padding: 'var(--space-xl)', borderRadius: 12, marginBottom: 'var(--space-lg)' }}>
          <h3 style={{ fontSize: 'var(--font-size-md)', fontWeight: 700, marginBottom: 'var(--space-md)', borderBottom: '1px solid var(--color-border)', paddingBottom: 'var(--space-xs)' }}>
            1. Target Coordinates & Naming
          </h3>

          <div className="input-group" style={{ marginBottom: 'var(--space-md)' }}>
            <label className="input-label">Exam Title</label>
            <input
              type="text"
              className="input"
              value={newTest.title}
              onChange={e => setNewTest({...newTest, title: e.target.value})}
              placeholder="e.g. End-Term Consolidated Aptitude Test"
              required
              disabled={creating}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 'var(--space-md)' }}>
            <div className="input-group">
              <label className="input-label">Campus Filter</label>
              <select
                className="input"
                value={newTest.branch}
                onChange={e => setNewTest({...newTest, branch: e.target.value})}
                disabled={creating}
              >
                <option value="ALL">ALL BRANCHES</option>
                <option value="Haldwani">Haldwani</option>
                <option value="Bhimtal">Bhimtal</option>
                <option value="Dehradun">Dehradun</option>
              </select>
            </div>

            <div className="input-group">
              <label className="input-label">Course Filter</label>
              <select
                className="input"
                value={newTest.course}
                onChange={e => setNewTest({...newTest, course: e.target.value})}
                disabled={creating}
              >
                <option value="ALL">ALL COURSES</option>
                <option value="B.Tech CSE">B.Tech CSE</option>
                <option value="B.Tech ECE">B.Tech ECE</option>
                <option value="BCA">BCA</option>
                <option value="MCA">MCA</option>
              </select>
            </div>

            <div className="input-group">
              <label className="input-label">Semester Range</label>
              <select
                className="input"
                value={newTest.semester}
                onChange={e => setNewTest({...newTest, semester: e.target.value})}
                disabled={creating}
              >
                <option value="ALL">ALL SEMESTERS</option>
                {getSemestersForCourse(newTest.course).map(s => (
                  <option key={s} value={String(s)}>Semester {s}</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* SCHEDULING AND EXAM SETTINGS */}
        <div className="card" style={{ padding: 'var(--space-xl)', borderRadius: 12, marginBottom: 'var(--space-lg)' }}>
          <h3 style={{ fontSize: 'var(--font-size-md)', fontWeight: 700, marginBottom: 'var(--space-md)', borderBottom: '1px solid var(--color-border)', paddingBottom: 'var(--space-xs)' }}>
            2. Timing parameters
          </h3>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 'var(--space-md)' }}>
            <div className="input-group">
              <label className="input-label">Date</label>
              <input
                type="date"
                className="input"
                value={newTest.startDate}
                onChange={e => setNewTest({...newTest, startDate: e.target.value})}
                required
                disabled={creating}
              />
            </div>
            <div className="input-group">
              <label className="input-label">Start Time</label>
              <input
                type="time"
                className="input"
                value={newTest.startTime}
                onChange={e => setNewTest({...newTest, startTime: e.target.value})}
                required
                disabled={creating}
              />
            </div>
            <div className="input-group">
              <label className="input-label">Duration (Minutes)</label>
              <input
                type="number"
                className="input"
                value={newTest.duration}
                onChange={e => {
                  const val = e.target.value;
                  setNewTest({...newTest, duration: val === '' ? '' : parseInt(val) ?? ''});
                }}
                min="5" max="300"
                required
                disabled={creating}
              />
            </div>
          </div>
        </div>

        {/* SCORING PARAMETERS */}
        <div className="card" style={{ padding: 'var(--space-xl)', borderRadius: 12, marginBottom: 'var(--space-lg)' }}>
          <h3 style={{ fontSize: 'var(--font-size-md)', fontWeight: 700, marginBottom: 'var(--space-md)', borderBottom: '1px solid var(--color-border)', paddingBottom: 'var(--space-xs)' }}>
            3. Scoring Details
          </h3>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-xl)', marginBottom: 'var(--space-md)' }}>
            <div>
              <label className="input-label">Marks Per Question</label>
              <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 4 }}>Aptitude Logic:</div>
                  <input
                    type="number"
                    className="input"
                    min="0"
                    max="10"
                    value={newTest.marksAptitude}
                    onChange={e => {
                      const val = e.target.value;
                      setNewTest({...newTest, marksAptitude: val === '' ? '' : parseInt(val) ?? ''});
                    }}
                    disabled={creating}
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 4 }}>English:</div>
                  <input
                    type="number"
                    className="input"
                    min="0"
                    max="10"
                    value={newTest.marksEnglish}
                    onChange={e => {
                      const val = e.target.value;
                      setNewTest({...newTest, marksEnglish: val === '' ? '' : parseInt(val) ?? ''});
                    }}
                    disabled={creating}
                  />
                </div>
              </div>
            </div>

            <div style={{ background: 'var(--color-bg-hover)', padding: 'var(--space-md)', borderRadius: 8 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontWeight: 600, marginBottom: 'var(--space-sm)' }}>
                <input type="checkbox" checked={newTest.negativeEnabled} onChange={e => setNewTest({...newTest, negativeEnabled: e.target.checked})} disabled={creating} />
                Subtract points on incorrect answers
              </label>

              {newTest.negativeEnabled && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-sm)', marginTop: 8 }}>
                  <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 4 }}>Aptitude penalty:</div>
                      <input type="number" step="0.05" min="0" max="10" className="input" value={newTest.negativeValueAptitude} onChange={e => setNewTest({...newTest, negativeValueAptitude: parseFloat(e.target.value) || 0})} disabled={creating || !newTest.negativeApplyAptitude} />
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 4 }}>English penalty:</div>
                      <input type="number" step="0.05" min="0" max="10" className="input" value={newTest.negativeValueEnglish} onChange={e => setNewTest({...newTest, negativeValueEnglish: parseFloat(e.target.value) || 0})} disabled={creating || !newTest.negativeApplyEnglish} />
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 'var(--space-sm)', alignItems: 'center', marginTop: 4 }}>
                    <span style={{ fontSize: '11px', color: 'var(--color-text-muted)' }}>Target segments:</span>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '11px', cursor: 'pointer' }}>
                      <input type="checkbox" checked={newTest.negativeApplyAptitude} onChange={e => setNewTest({...newTest, negativeApplyAptitude: e.target.checked})} disabled={creating} /> Aptitude
                    </label>
                    <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '11px', cursor: 'pointer' }}>
                      <input type="checkbox" checked={newTest.negativeApplyEnglish} onChange={e => setNewTest({...newTest, negativeApplyEnglish: e.target.checked})} disabled={creating} /> English
                    </label>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* POOL QUESTIONS CONFIG */}
        <div className="card" style={{ padding: 'var(--space-xl)', borderRadius: 12, marginBottom: 'var(--space-lg)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-md)', borderBottom: '1px solid var(--color-border)', paddingBottom: 'var(--space-xs)' }}>
            <h3 style={{ fontSize: 'var(--font-size-md)', fontWeight: 700, margin: 0 }}>
              4. Selection Parameters
            </h3>
            <button type="button" onClick={() => topicBankQuery.refetch()} className="btn btn-sm btn-ghost" disabled={loadingTopics} style={{ padding: '4px 8px', fontSize: '11px' }}>
              <RefreshCw size={12} className={loadingTopics || refreshingTopics ? "spin" : ""} style={{ marginRight: 4 }} />
              Refresh Topics
            </button>
          </div>

          {/* Total Questions input */}
          <div className="input-group" style={{ marginBottom: 'var(--space-lg)', maxWidth: '300px' }}>
            <label className="input-label">Total Questions Target</label>
            <input
              type="number"
              className="input"
              placeholder="e.g. 20"
              value={newTest.totalQuestions || ''}
              onChange={e => handleTotalQuestionsChange(parseInt(e.target.value) || 0)}
              min="1"
              max="300"
              required
              disabled={creating}
            />
            <span style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: 4 }}>
              Sets the limit of the test. Questions will be divided among checked sections.
            </span>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-md)' }}>

            {/* Aptitude Pool */}
            <div style={{ border: '1px solid var(--color-border)', borderRadius: 8, padding: 'var(--space-md)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-sm)' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontWeight: 700, color: 'var(--color-accent)' }}>
                  <input
                    type="checkbox"
                    checked={Number(newTest.splitA) > 0}
                    onChange={e => {
                      const checked = e.target.checked;
                      setNewTest(prev => {
                        let A = checked ? (Number(prev.totalQuestions) > 0 ? Math.floor(Number(prev.totalQuestions) / 2) || 5 : 10) : 0;
                        let T = Number(prev.totalQuestions) || (A + Number(prev.splitE));
                        if (!checked) {
                          T = Number(prev.splitE);
                        } else if (Number(prev.splitE) === 0) {
                          T = A;
                        } else {
                          T = A + Number(prev.splitE);
                        }
                        return { ...prev, splitA: A, totalQuestions: T };
                      });
                    }}
                  />
                  Aptitude Section
                </label>
                {Number(newTest.splitA) > 0 && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ fontSize: 'var(--font-size-xs)' }}>Questions to Fetch:</span>
                    <input
                      type="number"
                      className="input"
                      style={{ width: 70, padding: '4px 8px' }}
                      value={newTest.splitA}
                      min="1"
                      max="200"
                      onChange={e => {
                        const val = e.target.value;
                        handleSplitAChange(val === '' ? 0 : parseInt(val, 10) || 0);
                      }}
                      disabled={creating}
                      />
                  </div>
                )}
              </div>

              {Number(newTest.splitA) > 0 && (
                <div style={{ marginTop: 12 }}>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 8 }}>
                    Choose eligible topic rules ({selectedAptTopics.length}) | Total Units Available: {dbAptitudeTopics.length}
                  </div>
                  {loadingTopics ? <div style={{ fontSize: '11px' }}>Analyzing bank...</div> : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, maxHeight: 150, overflowY: 'auto', background: 'var(--color-bg-hover)', padding: 8, borderRadius: 6 }}>
                      {dbAptitudeTopics.map(t => (
                        <label key={t} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '11px', cursor: 'pointer' }}>
                          <input type="checkbox" checked={selectedAptTopics.includes(t)} onChange={() => handleToggleTopic('APT', t)} />
                          <span>{t} <span style={{ color: 'var(--color-text-muted)', marginLeft: 4 }}>({topicCounts[t] || 0} in database)</span></span>
                        </label>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* English Pool */}
            <div style={{ border: '1px solid var(--color-border)', borderRadius: 8, padding: 'var(--space-md)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-sm)' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontWeight: 700, color: '#a855f7' }}>
                  <input
                    type="checkbox"
                    checked={Number(newTest.splitE) > 0}
                    onChange={e => {
                      const checked = e.target.checked;
                      setNewTest(prev => {
                        let E = checked ? (Number(prev.totalQuestions) > 0 ? (Number(prev.totalQuestions) - Number(prev.splitA)) || 5 : 10) : 0;
                        let T = Number(prev.totalQuestions) || (Number(prev.splitA) + E);
                        if (!checked) {
                          T = Number(prev.splitA);
                        } else if (Number(prev.splitA) === 0) {
                          T = E;
                        } else {
                          T = Number(prev.splitA) + E;
                        }
                        return { ...prev, splitE: E, totalQuestions: T };
                      });
                    }}
                  />
                  English / Verbal Section
                </label>
                {Number(newTest.splitE) > 0 && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ fontSize: 'var(--font-size-xs)' }}>Questions to Fetch:</span>
                    <input
                      type="number"
                      className="input"
                      style={{ width: 70, padding: '4px 8px' }}
                      value={newTest.splitE}
                      min="1"
                      max="200"
                      onChange={e => {
                        const val = e.target.value;
                        handleSplitEChange(val === '' ? 0 : parseInt(val, 10) || 0);
                      }}
                      disabled={creating}
                    />
                  </div>
                )}
              </div>

              {Number(newTest.splitE) > 0 && (
                <div style={{ marginTop: 12 }}>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 8 }}>
                    Choose eligible topic rules ({selectedEngTopics.length}) | Total Units Available: {dbEnglishTopics.length}
                  </div>
                  {loadingTopics ? <div style={{ fontSize: '11px' }}>Analyzing bank...</div> : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, maxHeight: 150, overflowY: 'auto', background: 'var(--color-bg-hover)', padding: 8, borderRadius: 6 }}>
                      {dbEnglishTopics.map(t => (
                        <label key={t} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: '11px', cursor: 'pointer' }}>
                          <input type="checkbox" checked={selectedEngTopics.includes(t)} onChange={() => handleToggleTopic('ENG', t)} />
                          <span>{t} <span style={{ color: 'var(--color-text-muted)', marginLeft: 4 }}>({topicCounts[t] || 0} in database)</span></span>
                        </label>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>

          </div>

          <div style={{
            marginTop: 'var(--space-lg)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '14px var(--space-md)',
            background: 'var(--color-bg-hover)',
            borderRadius: 8,
            fontWeight: 700
          }}>
            <span style={{ fontSize: 'var(--font-size-sm)' }}>Target Question Density:</span>
            <span style={{ color: 'var(--color-accent)' }}>{numericValue(newTest.splitA) + numericValue(newTest.splitE)} of {numericValue(newTest.totalQuestions)} Questions Set</span>
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-sm)', marginTop: 'var(--space-xl)' }}>
          <button
            type="submit"
            className="btn btn-primary"
            style={{ width: '100%', padding: '16px', fontSize: 'var(--font-size-md)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}
            disabled={creating}
          >
            {creating ? (
              <>
                <Loader2 className="spin" size={20} />
                Synchronizing configurations across schemas...
              </>
            ) : 'Assemble Manual Mock Test'}
          </button>
        </div>
      </form>
    </div>
  );
}
