"use client";

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Eye, EyeOff, Mail, Lock, ArrowRight } from 'lucide-react';
import { useAuth } from '../../providers/AuthProvider';

export default function LoginPage() {
  const { login } = useAuth();
  const router = useRouter();

  const [email, setEmail] = useState(typeof window !== 'undefined' ? localStorage.getItem('rememberedEmail') || '' : '');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(typeof window !== 'undefined' && !!localStorage.getItem('rememberedEmail'));
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const validateEmail = (e: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email.trim()) {
      setError('Email address is required');
      return;
    }

    if (!validateEmail(email)) {
      setError('Please enter a valid email address');
      return;
    }

    if (!password) {
      setError('Password is required');
      return;
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters');
      return;
    }

    setLoading(true);
    try {
      const result = await login(email.trim(), password);

      if (rememberMe) {
        localStorage.setItem('rememberedEmail', email.trim());
      } else {
        localStorage.removeItem('rememberedEmail');
      }

      const accountType = result?.user?.identity?.account_type;
      if (accountType === 'ADMIN') {
        router.replace('/admin');
      } else if (accountType === 'STUDENT') {
        router.replace('/dashboard');
      } else {
        // If profile lookup is temporarily slow, do not send a valid auth user to locked.
        router.replace(email.trim().toLowerCase().includes('admin') ? '/admin' : '/dashboard');
      }
    } catch (err: any) {
      setError(err?.message || 'Invalid email or password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <div className="login-bg">
        <div className="login-bg-orb login-bg-orb-1"></div>
        <div className="login-bg-orb login-bg-orb-2"></div>
        <div className="login-bg-orb login-bg-orb-3"></div>
      </div>

      <div className="login-container animate-fade-in-up">
        <div className="login-brand">
          <div className="login-logo">G</div>
          <h1 className="login-title">GEHU Connect</h1>
          <p className="login-subtitle">Campus ERP - Graphic Era Hill University</p>
        </div>

        <div className="login-card">
          <h2 className="login-card-title">Welcome Back</h2>
          <p className="login-card-subtitle">Sign in to your account</p>

          <form onSubmit={handleSubmit} className="login-form">
            <div className="input-group">
              <label className="input-label" htmlFor="login-email">Email Address</label>
              <div className="login-input-wrapper">
                <Mail size={18} className="login-input-icon" />
                <input
                  id="login-email"
                  type="email"
                  className={`input login-input ${error && !validateEmail(email) ? 'input-error' : ''}`}
                  placeholder="you@gehu.ac.in"
                  value={email}
                  onChange={(e) => { setEmail(e.target.value); setError(''); }}
                  autoComplete="email"
                  autoFocus
                />
              </div>
            </div>

            <div className="input-group">
              <label className="input-label" htmlFor="login-password">Password</label>
              <div className="login-input-wrapper">
                <Lock size={18} className="login-input-icon" />
                <input
                  id="login-password"
                  type={showPassword ? 'text' : 'password'}
                  className={`input login-input ${error && password.length < 6 ? 'input-error' : ''}`}
                  placeholder="********"
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); setError(''); }}
                  autoComplete="current-password"
                />
                <button
                  type="button"
                  className="login-input-toggle"
                  onClick={() => setShowPassword(!showPassword)}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <div className="login-options">
              <label className="checkbox-group">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                />
                <span className="login-remember-text">Remember email</span>
              </label>
            </div>

            {error && <div className="login-error">{error}</div>}

            <button
              type="submit"
              className="btn btn-primary btn-lg login-submit"
              disabled={loading}
            >
              {loading ? (
                <span className="spinner" style={{ width: 20, height: 20 }}></span>
              ) : (
                <>
                  Sign In
                  <ArrowRight size={18} />
                </>
              )}
            </button>
          </form>

          <div style={{ marginTop: 'var(--space-lg)', padding: 'var(--space-md)', borderRadius: 'var(--radius-md)', background: 'var(--color-bg-elevated)', fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)' }}>
            <div style={{ fontWeight: 600, marginBottom: 4 }}>Pilot Credentials:</div>
            <div>Admin: admin@test.gehu</div>
            <div>Student: student@test.gehu</div>
            <div>Students: test1@gehu.ac.in, test2@gehu.ac.in</div>
            <div>Password: use the Supabase Auth password set for these accounts.</div>
          </div>
        </div>

        <p className="login-footer">(c) 2026 Graphic Era Hill University. All rights reserved.</p>
      </div>
    </div>
  );
}
