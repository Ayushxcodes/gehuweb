"use client";

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { User, GraduationCap, MapPin, Users as UsersIcon, Save, ChevronRight, ChevronLeft } from 'lucide-react';
import { useAuth } from '../../providers/AuthProvider';
import { Courses, Semesters, Branches } from '../../../utils/constants';
import { supabase } from '../../../utils/supabaseClient';

export default function ProfileSetupPage() {
  const { user, refreshProfile } = useAuth();
  const router = useRouter();
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [form, setForm] = useState({
    name: '', studentId: '', rollNo: '', gender: '', dob: '', category: '',
    course: '', semester: '', branch: '', batchYear: '',
    studentMobile: '', phone: '',
    fatherName: '', fatherMobile: '', fatherOccupation: '',
    motherName: '', motherMobile: '', motherOccupation: '',
    permanentAddress: '', city: '', state: '', pin: '',
    highSchoolYear: '', highSchoolMarks: '',
    intermediateYear: '', intermediateMarks: '',
  });

  const update = (key: string, value: any) => setForm((prev: any) => ({ ...prev, [key]: value }));

  const handleSubmit = async () => {
    setError('');
    if (!form.name || !form.course || !form.semester) {
      setError('Name, Course, and Semester are required.');
      return;
    }
    setLoading(true);
    try {
      const profilePayload = {
        full_name: form.name,
        dob: form.dob,
        gender_code: form.gender?.toUpperCase?.(),
        category_code: form.category?.toUpperCase?.()?.substring(0, 3),
        ubi_code: form.studentId,
        personal_email: '',
        primary_phone: form.studentMobile,
        alternate_phone: form.phone,
        father_name: form.fatherName,
        father_phone: form.fatherMobile,
        father_occupation: form.fatherOccupation,
        mother_name: form.motherName,
        mother_phone: form.motherMobile,
        mother_occupation: form.motherOccupation,
        permanent_line1: form.permanentAddress,
        permanent_line2: '',
        city_name: form.city,
        state_name: form.state,
        pin_code: form.pin,
        country_name: 'India',
        campus_code: 'GEHU_DEHRADUN',
        course_code: form.course,
        branch_code: form.branch,
        specialization_code: null,
        section_code: null,
        semester: parseInt(form.semester) || null,
        class_roll_no: parseInt(form.rollNo) || null,
        enroll_no: form.studentId,
        university_roll_no: form.rollNo,
        high_school_percent: parseFloat(form.highSchoolMarks) || null,
        intermediate_percent: parseFloat(form.intermediateMarks) || null,
        bachelor_percent: null,
      };

      console.log('Submitting Profile RPC Payload:', profilePayload);
      alert('Profile Submission is temporarily locked until the Android team finalizes the database RPC (api_student_submit_profile). Your payload was logged to the console.');

      /*
      // Final implementation when RPC exists:
      const { data, error } = await supabase.rpc('api_student_submit_profile', {
        p_profile: profilePayload,
      });
      if (error) throw error;
      await refreshProfile();
      router.replace('/auth/pending');
      */
    } catch (err: any) {
      setError(err?.message || String(err));
    } finally {
      setLoading(false);
    }
  };

  const steps = [
    { icon: User, label: 'Personal' },
    { icon: GraduationCap, label: 'Academic' },
    { icon: UsersIcon, label: 'Family' },
    { icon: MapPin, label: 'Address' },
  ];

  const renderField = (label: string, key: string, type = 'text', options: any = null) => (
    <div className="input-group" key={key}>
      <label className="input-label">{label}</label>
      {options ? (
        <select className="input" value={(form as any)[key]} onChange={e => update(key, e.target.value)}>
          <option value="">Select {label}</option>
          {options.map((o: any) => <option key={o} value={o}>{o}</option>)}
        </select>
      ) : (
        <input
          className="input"
          type={type}
          placeholder={label}
          value={(form as any)[key]}
          onChange={e => update(key, e.target.value)}
        />
      )}
    </div>
  );

  return (
    <div style={{ minHeight: '100vh', background: 'var(--color-bg-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 'var(--space-lg)' }}>
      <div style={{ width: '100%', maxWidth: 640 }} className="animate-fade-in-up">
        <div style={{ textAlign: 'center', marginBottom: 'var(--space-xl)' }}>
          <h1 style={{ fontSize: 'var(--font-size-2xl)', fontWeight: 800, color: 'var(--color-text-primary)' }}>Complete Your Profile</h1>
          <p style={{ color: 'var(--color-text-muted)', fontSize: 'var(--font-size-sm)', marginTop: 4 }}>Fill in your details to continue</p>
        </div>

        <div style={{ display: 'flex', justifyContent: 'center', gap: 8, marginBottom: 'var(--space-xl)' }}>
          {steps.map((s, i) => (
            <button
              key={i}
              onClick={() => setStep(i + 1)}
              style={{
                display: 'flex', alignItems: 'center', gap: 6, padding: '8px 16px',
                borderRadius: 'var(--radius-full)', fontSize: 'var(--font-size-sm)',
                fontWeight: step === i + 1 ? 600 : 400,
                background: step === i + 1 ? 'var(--color-accent-subtle)' : 'transparent',
                color: step === i + 1 ? 'var(--color-accent)' : 'var(--color-text-muted)',
                border: 'none', cursor: 'pointer', transition: 'all 200ms'
              }}
            >
              <s.icon size={16} />
              <span>{s.label}</span>
            </button>
          ))}
        </div>

        <div className="card" style={{ padding: 'var(--space-xl)' }}>
          {step === 1 && (
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-md)' }}>
              {renderField('Full Name *', 'name')}
              {renderField('Student ID', 'studentId')}
              {renderField('Roll Number', 'rollNo')}
              {renderField('Gender', 'gender', 'text', ['Male', 'Female', 'Other'])}
              {renderField('Date of Birth', 'dob', 'date')}
              {renderField('Category', 'category', 'text', ['General', 'OBC', 'SC', 'ST', 'EWS'])}
              {renderField('Student Mobile', 'studentMobile', 'tel')}
              {renderField('Phone', 'phone', 'tel')}
            </div>
          )}

          {step === 2 && (
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-md)' }}>
              {renderField('Course *', 'course', 'text', Courses)}
              {renderField('Semester *', 'semester', 'text', Semesters)}
              {renderField('Branch / Campus', 'branch', 'text', [Branches.DEHRADUN, Branches.HALDWANI, Branches.BHIMTAL])}
              {renderField('Batch Year', 'batchYear', 'number')}
              {renderField('High School Year', 'highSchoolYear')}
              {renderField('High School Marks %', 'highSchoolMarks')}
              {renderField('Intermediate Year', 'intermediateYear')}
              {renderField('Intermediate Marks %', 'intermediateMarks')}
            </div>
          )}

          {step === 3 && (
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-md)' }}>
              {renderField("Father's Name", 'fatherName')}
              {renderField("Father's Mobile", 'fatherMobile', 'tel')}
              {renderField("Father's Occupation", 'fatherOccupation')}
              {renderField("Mother's Name", 'motherName')}
              {renderField("Mother's Mobile", 'motherMobile', 'tel')}
              {renderField("Mother's Occupation", 'motherOccupation')}
            </div>
          )}

          {step === 4 && (
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-md)' }}>
              <div style={{ gridColumn: '1 / -1' }}>{renderField('Permanent Address', 'permanentAddress')}</div>
              {renderField('City', 'city')}
              {renderField('State', 'state')}
              {renderField('PIN Code', 'pin')}
            </div>
          )}

          {error && <div className="login-error" style={{ marginTop: 'var(--space-md)' }}>{error}</div>}

          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 'var(--space-xl)' }}>
            <button
              className="btn btn-secondary"
              onClick={() => setStep(Math.max(1, step - 1))}
              disabled={step === 1}
            >
              <ChevronLeft size={18} /> Back
            </button>

            {step < 4 ? (
              <button className="btn btn-primary" onClick={() => setStep(step + 1)}>
                Next <ChevronRight size={18} />
              </button>
            ) : (
              <button className="btn btn-primary" onClick={handleSubmit} disabled={loading}>
                {loading ? <span className="spinner" style={{ width: 18, height: 18 }}></span> : <><Save size={18} /> Submit Profile</>}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

