"use client";

import React, { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { supabase } from '../../../../utils/supabaseClient';
import { UploadCloud, CheckCircle, ArrowLeft, ChevronLeft, ChevronRight, Loader2 } from 'lucide-react';
import Papa from 'papaparse';

interface ParsedCsvQuestion {
  subject_type: 'APTITUDE' | 'ENGLISH';
  topic: string;
  question: string;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  answer_letter: string;
  solution: string;
  difficulty: string;
  is_active: boolean;
}

interface CsvTestConfig {
  title: string;
  branch: string;
  course: string;
  semester: string;
  duration: number | '';
  marksAptitude: number | '';
  marksEnglish: number | '';
  negativeEnabled: boolean;
  negativeValueAptitude: number | '';
  negativeValueEnglish: number | '';
  negativeApplyAptitude: boolean;
  negativeApplyEnglish: boolean;
  isMainExam: boolean;
  startDate: string;
  startTime: string;
}

export default function CreateCsvMockPage() {
  const router = useRouter();

  const [creating, setCreating] = useState(false);
  const [csvFile, setCsvFile] = useState<File | null>(null);
  const [isDragActive, setIsDragActive] = useState(false);
  const [parsingCsv, setParsingCsv] = useState(false);
  const [parseResults, setParseResults] = useState<{
    rawCount: number;
    totalValid: number;
    aptitudeCount: number;
    englishCount: number;
    skippedCount: number;
    questions: ParsedCsvQuestion[];
  } | null>(null);

  const [previewPage, setPreviewPage] = useState(1);
  const itemsPerPage = 8;

  // Form State
  const [newTest, setNewTest] = useState<CsvTestConfig>({
    title: '',
    branch: 'ALL',
    course: 'ALL',
    semester: 'ALL',
    duration: 60,
    marksAptitude: 1,
    marksEnglish: 2,
    negativeEnabled: false,
    negativeValueAptitude: 0.25,
    negativeValueEnglish: 0.25,
    negativeApplyAptitude: true,
    negativeApplyEnglish: true,
    isMainExam: false,
    startDate: '',
    startTime: '',
  });

  const getSemestersForCourse = (course: string) => {
    if (course === 'ALL') return [];
    if (course === 'MCA') return [1, 2, 3, 4];
    if (course === 'BCA') return [1, 2, 3, 4, 5, 6];
    return [1, 2, 3, 4, 5, 6, 7, 8];
  };

  const handleDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') setIsDragActive(true);
    else if (e.type === 'dragleave') setIsDragActive(false);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragActive(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFileChange(e.dataTransfer.files[0]);
    }
  }, []);

  const handleFileChange = (file: File | undefined) => {
    if (!file) return;
    if (file.type !== 'text/csv' && !file.name.endsWith('.csv')) {
      alert("Please upload a valid CSV file.");
      return;
    }
    setCsvFile(file);
    parseCsvFile(file);
  };

  const parseCsvFile = (file: File) => {
    setParsingCsv(true);
    setParseResults(null);
    setPreviewPage(1);

    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: (results) => {
        const rawData = results.data;
        const validQuestions: ParsedCsvQuestion[] = [];
        let aptCount = 0;
        let engCount = 0;
        let skipped = 0;

        rawData.forEach((row: any) => {
          const rawSubject = (row['subject'] || row['subject_type'] || '').toString().trim().toUpperCase();
          const topic = (row['topic'] || 'General').toString().trim();
          const qText = (row['question'] || row['question_text'] || '').toString().trim();
          const aText = (row['option_a'] || row['A'] || '').toString().trim();
          const bText = (row['option_b'] || row['B'] || '').toString().trim();
          const cText = (row['option_c'] || row['C'] || '').toString().trim();
          const dText = (row['option_d'] || row['D'] || '').toString().trim();
          const ansText = (row['answer_letter'] || row['correct_answer'] || row['answer'] || '').toString().trim().toUpperCase();
          const solText = (row['solution'] || row['explanation'] || '').toString().trim();
          const diffText = (row['difficulty'] || 'medium').toString().trim().toLowerCase();
          const activeStatus = row['is_active'] ? row['is_active'].toString().toLowerCase() : 'true';

          if (activeStatus === 'false' || activeStatus === '0') {
            skipped++;
            return;
          }

          if (!qText || !aText || !bText || !ansText) {
            skipped++;
            return;
          }

          let cleanSubject: 'APTITUDE' | 'ENGLISH' = 'APTITUDE';
          if (rawSubject.includes('ENG') || rawSubject.includes('VERBAL')) {
            cleanSubject = 'ENGLISH';
            engCount++;
          } else {
            aptCount++;
          }

          let cleanAns = ansText;
          if (cleanAns.length > 1) {
            cleanAns = cleanAns.substring(0, 1);
          }

          validQuestions.push({
            subject_type: cleanSubject,
            topic: topic,
            question: qText,
            option_a: aText,
            option_b: bText,
            option_c: cText,
            option_d: dText,
            answer_letter: cleanAns,
            solution: solText,
            difficulty: diffText,
            is_active: true
          });
        });

        setParseResults({
          rawCount: rawData.length,
          totalValid: validQuestions.length,
          aptitudeCount: aptCount,
          englishCount: engCount,
          skippedCount: skipped,
          questions: validQuestions
        });
        setParsingCsv(false);
      },
      error: (error) => {
        console.error('Error parsing CSV:', error);
        alert('Failed to parse CSV: ' + error.message);
        setParsingCsv(false);
      }
    });
  };

  async function handleCreateTest(e: React.FormEvent) {
    e.preventDefault();
    if (!parseResults || parseResults.totalValid === 0) {
      return alert("Please upload a valid CSV with parseable questions.");
    }
    
    setCreating(true);
    try {
      const negativeApplyTo: string[] = [];
      if (newTest.negativeEnabled) {
        if (newTest.negativeApplyAptitude) negativeApplyTo.push('Aptitude');
        if (newTest.negativeApplyEnglish) negativeApplyTo.push('English');
      }

      const durationVal = newTest.duration === '' ? 0 : newTest.duration;
      const combinedDateTimeStr = `${newTest.startDate}T${newTest.startTime}:00`;
      const combinedDateTime = new Date(combinedDateTimeStr);
      const nowIso = new Date().toISOString();
      const examEnd = new Date(combinedDateTime);
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
      const frozenIds = parseResults.questions.map((_, idx) => `${testId}_q${idx}`);

      // 1. Storage payload sync for legacy client devices
      const fileBuffer = new Blob([JSON.stringify(parseResults.questions)], { type: 'application/json' });
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

      // 2. Write to public.app_mock_tests config
      const { error: pubTestErr } = await supabase
        .from('app_mock_tests')
        .insert([{
          test_id: testId,
          title: newTest.title.trim() || 'Untitled CSV Auto Mock',
          duration_minutes: durationVal,
          requires_web_proctoring: newTest.isMainExam,
          payload_cdn_url: cdnUrl,
          start_at: combinedDateTime.toISOString(),
          created_at: nowIso
        }]);
      if (pubTestErr) throw pubTestErr;

      // 3. Write to mocks.mock_tests with extra campus targeting
      const { error: mockTestErr } = await supabase
        .schema('mocks')
        .from('mock_tests')
        .insert([{
          test_id: testId,
          title: newTest.title.trim() || 'Untitled CSV Auto Mock',
          branch: newTest.branch === 'ALL' ? 'ALL' : newTest.branch,
          course: newTest.course === 'ALL' ? 'ALL' : newTest.course,
          semester: newTest.semester === 'ALL' ? 'ALL' : String(parseInt(newTest.semester, 10)),
          total_questions: parseResults.totalValid,
          duration_minutes: durationVal,
          start_at: combinedDateTime.toISOString(),
          scheduled_start_at: combinedDateTime.toISOString(),
          exam_end_at: examEnd.toISOString(),
          expires_at: expires.toISOString(),
          status: 'POSTED',
          source: 'csv',
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

      // 4. Write to public.app_mock_questions
      const publicQuestionRows = parseResults.questions.map((q) => ({
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

      // 5. Write to mocks.mock_test_questions
      const mockQuestionRows = parseResults.questions.map((q, idx) => ({
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
        source: 'csv',
        uploaded_at: nowIso
      }));

      const { error: mockQuestErr } = await supabase
        .schema('mocks')
        .from('mock_test_questions')
        .insert(mockQuestionRows);
      if (mockQuestErr) throw mockQuestErr;

      alert(`Success! Generated test: "${newTest.title}"`);
      router.push('/admin/mock-tests/manage');

    } catch (err: any) {
      console.error(err);
      alert('Error creating CSV test: ' + (err.message || String(err)));
    } finally {
      setCreating(false);
    }
  }

  const currentPreviewData = parseResults?.questions.slice((previewPage - 1) * itemsPerPage, previewPage * itemsPerPage) || [];
  const totalPages = parseResults ? Math.ceil(parseResults.questions.length / itemsPerPage) : 0;

  return (
    <div style={{ maxWidth: 850, margin: '0 auto', paddingBottom: 100 }}>
      <div className="page-header" style={{ marginBottom: 'var(--space-md)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-md)' }}>
          <Link href="/admin/organize" className="btn btn-ghost btn-icon">
            <ArrowLeft size={20} />
          </Link>
          <div>
            <div className="page-title">CSV Auto Mock Test</div>
            <div className="page-subtitle">Batch upload questions to construct tests instantly</div>
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
                Locks visibility window parameters, restricts copy-paste inputs, captures exit events, and tracks warning thresholds.
              </div>
            </div>
          </label>
        </div>

        {/* IDENTIFICATION BLOCK */}
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
              placeholder="e.g. Uploaded Exam Batch A" 
              required 
              disabled={creating}
            />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 'var(--space-md)' }}>
            <div className="input-group">
              <label className="input-label">Campus Target</label>
              <select className="input" value={newTest.branch} onChange={e => setNewTest({...newTest, branch: e.target.value})} disabled={creating}>
                <option value="ALL">ALL BRANCHES</option>
                <option value="Haldwani">Haldwani</option>
                <option value="Bhimtal">Bhimtal</option>
                <option value="Dehradun">Dehradun</option>
              </select>
            </div>
            <div className="input-group">
              <label className="input-label">Course Target</label>
              <select className="input" value={newTest.course} onChange={e => setNewTest({...newTest, course: e.target.value})} disabled={creating}>
                <option value="ALL">ALL COURSES</option>
                <option value="B.Tech CSE">B.Tech CSE</option>
                <option value="BCA">BCA</option>
                <option value="MCA">MCA</option>
              </select>
            </div>
            <div className="input-group">
              <label className="input-label">Semester Range</label>
              <select className="input" value={newTest.semester} onChange={e => setNewTest({...newTest, semester: e.target.value})} disabled={creating}>
                <option value="ALL">ALL SEMESTERS</option>
                {getSemestersForCourse(newTest.course).map(s => <option key={s} value={String(s)}>Semester {s}</option>)}
              </select>
            </div>
          </div>
        </div>

        {/* TIMING AND CONFIG */}
        <div className="card" style={{ padding: 'var(--space-xl)', borderRadius: 12, marginBottom: 'var(--space-lg)' }}>
          <h3 style={{ fontSize: 'var(--font-size-md)', fontWeight: 700, marginBottom: 'var(--space-md)', borderBottom: '1px solid var(--color-border)', paddingBottom: 'var(--space-xs)' }}>
            2. Timing parameters
          </h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 'var(--space-md)' }}>
            <div className="input-group">
              <label className="input-label">Date</label>
              <input type="date" className="input" value={newTest.startDate} onChange={e => setNewTest({...newTest, startDate: e.target.value})} required disabled={creating}/>
            </div>
            <div className="input-group">
              <label className="input-label">Start Time</label>
              <input type="time" className="input" value={newTest.startTime} onChange={e => setNewTest({...newTest, startTime: e.target.value})} required disabled={creating}/>
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
                min="5" 
                required 
                disabled={creating}
              />
            </div>
          </div>
        </div>

        {/* GRADING CONSTRAINTS */}
        <div className="card" style={{ padding: 'var(--space-xl)', borderRadius: 12, marginBottom: 'var(--space-lg)' }}>
          <h3 style={{ fontSize: 'var(--font-size-md)', fontWeight: 700, marginBottom: 'var(--space-md)', borderBottom: '1px solid var(--color-border)', paddingBottom: 'var(--space-xs)' }}>
            3. Scoring Details
          </h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-xl)', marginBottom: 'var(--space-md)' }}>
            <div>
              <label className="input-label">Marks Per Question</label>
              <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 4 }}>Aptitude:</div>
                  <input 
                    type="number" 
                    className="input" 
                    value={newTest.marksAptitude} 
                    onChange={e => {
                      const val = e.target.value;
                      setNewTest({...newTest, marksAptitude: val === '' ? '' : parseInt(val) ?? ''});
                    }} 
                    min="0" 
                    required 
                    disabled={creating} 
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 4 }}>English:</div>
                  <input 
                    type="number" 
                    className="input" 
                    value={newTest.marksEnglish} 
                    onChange={e => {
                      const val = e.target.value;
                      setNewTest({...newTest, marksEnglish: val === '' ? '' : parseInt(val) ?? ''});
                    }} 
                    min="0" 
                    required 
                    disabled={creating} 
                  />
                </div>
              </div>
            </div>
            
            <div style={{ background: 'var(--color-bg-hover)', padding: 'var(--space-md)', borderRadius: 8 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', fontWeight: 600 }}>
                <input type="checkbox" checked={newTest.negativeEnabled} onChange={e => setNewTest({...newTest, negativeEnabled: e.target.checked})} disabled={creating} />
                Subtract points on incorrect answers
              </label>
              {newTest.negativeEnabled && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-sm)', marginTop: 8 }}>
                  <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 4 }}>Aptitude penalty:</div>
                      <input 
                        type="number" 
                        step="0.05" 
                        min="0" 
                        max="10" 
                        className="input" 
                        value={newTest.negativeValueAptitude} 
                        onChange={e => {
                          const val = e.target.value;
                          setNewTest({...newTest, negativeValueAptitude: val === '' ? '' : parseFloat(val) ?? ''});
                        }} 
                        disabled={creating || !newTest.negativeApplyAptitude} 
                      />
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginBottom: 4 }}>English penalty:</div>
                      <input 
                        type="number" 
                        step="0.05" 
                        min="0" 
                        max="10" 
                        className="input" 
                        value={newTest.negativeValueEnglish} 
                        onChange={e => {
                          const val = e.target.value;
                          setNewTest({...newTest, negativeValueEnglish: val === '' ? '' : parseFloat(val) ?? ''});
                        }} 
                        disabled={creating || !newTest.negativeApplyEnglish} 
                      />
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

        {/* UPLOAD CONTAINER */}
        <div className="card" style={{ padding: 'var(--space-xl)', borderRadius: 12, marginBottom: 'var(--space-lg)' }}>
          <h3 style={{ fontSize: 'var(--font-size-md)', fontWeight: 700, marginBottom: 'var(--space-md)', borderBottom: '1px solid var(--color-border)', paddingBottom: 'var(--space-xs)' }}>
            4. CSV Upload Target
          </h3>
          <div 
            className={`dropzone ${isDragActive ? 'drag-active' : ''}`} 
            onDragEnter={handleDrag} 
            onDragOver={handleDrag} 
            onDragLeave={handleDrag} 
            onDrop={handleDrop} 
            style={{ 
              border: '2px dashed var(--color-border)', 
              borderRadius: 8, 
              padding: '40px 20px', 
              textAlign: 'center', 
              cursor: 'pointer', 
              background: isDragActive ? 'var(--color-bg-hover)' : 'transparent', 
              transition: 'all 0.2s ease' 
            }} 
            onClick={() => document.getElementById('csv-file-picker')?.click()}
          >
            <input id="csv-file-picker" type="file" accept=".csv" style={{ display: 'none' }} onChange={e => handleFileChange(e.target.files?.[0])} disabled={creating} />
            <UploadCloud size={44} color="var(--color-accent)" style={{ margin: '0 auto 12px' }} />
            <div style={{ fontWeight: 700, fontSize: 'var(--font-size-md)' }}>
              {csvFile ? csvFile.name : 'Drag and drop your spreadsheet or click to browse'}
            </div>
            <div style={{ fontSize: '11px', color: 'var(--color-text-muted)', marginTop: 6 }}>
              Supports headers: subject, topic, question, option_a/b/c/d, correct_answer
            </div>
          </div>

          {parsingCsv && <div style={{ textAlign: 'center', padding: 20 }}>Parsing file data...</div>}

          {parseResults && (
            <div style={{ marginTop: 'var(--space-lg)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-md)' }}>
                <h4 style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--color-success)', margin: 0, fontWeight: 700 }}>
                  <CheckCircle size={18} /> File verification successful! ({parseResults.totalValid} valid questions)
                </h4>
                {parseResults.skippedCount > 0 && (
                  <span style={{ fontSize: '11px', color: 'var(--color-error)' }}>
                    Skipped {parseResults.skippedCount} incomplete rows.
                  </span>
                )}
              </div>

              <div className="table-container">
                <table className="table" style={{ fontSize: '12px' }}>
                  <thead>
                    <tr>
                      <th>Segment</th>
                      <th>Topic</th>
                      <th>Question Statement</th>
                      <th>Key</th>
                    </tr>
                  </thead>
                  <tbody>
                    {currentPreviewData.map((q, idx) => (
                      <tr key={idx}>
                        <td>
                          <span className="badge" style={{ 
                            fontSize: '9px', 
                            background: q.subject_type === 'APTITUDE' ? 'rgba(59, 130, 246, 0.15)' : 'rgba(168, 85, 247, 0.15)',
                            color: q.subject_type === 'APTITUDE' ? '#3b82f6' : '#a855f7'
                          }}>
                            {q.subject_type}
                          </span>
                        </td>
                        <td>{q.topic}</td>
                        <td style={{ maxWidth: 280, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {q.question}
                        </td>
                        <td style={{ color: 'var(--color-success)', fontWeight: 700 }}>{q.answer_letter}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {totalPages > 1 && (
                <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 10, marginTop: 'var(--space-md)' }}>
                  <button type="button" className="btn btn-sm btn-ghost" onClick={() => setPreviewPage(p => Math.max(1, p - 1))} disabled={previewPage === 1}>
                    <ChevronLeft size={16} />
                  </button>
                  <span style={{ fontSize: 'var(--font-size-xs)' }}>Page {previewPage} of {totalPages}</span>
                  <button type="button" className="btn btn-sm btn-ghost" onClick={() => setPreviewPage(p => Math.min(totalPages, p + 1))} disabled={previewPage === totalPages}>
                    <ChevronRight size={16} />
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

        <button 
          type="submit" 
          className="btn btn-primary" 
          style={{ width: '100%', padding: '16px', marginTop: 'var(--space-lg)', fontSize: 'var(--font-size-md)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }} 
          disabled={creating || !parseResults}
        >
          {creating ? (
            <>
              <Loader2 className="spin" size={20} />
              Synchronizing configurations across schemas...
            </>
          ) : 'Construct CSV Auto Mock Test'}
        </button>
      </form>
    </div>
  );
}
