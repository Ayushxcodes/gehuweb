"use client";

import React from 'react';
import Link from 'next/link';
import { ClipboardList, Upload, Database, ArrowLeft } from 'lucide-react';

/**
 * AdminMockTestsPage — 1:1 Next.js App Router TSX replica of MockHostSelectionPage.jsx
 * Offers three actions:
 *   1. Manual Mock Test → /admin/mock-tests/manual
 *   2. CSV Auto Mock Test → /admin/mock-tests/csv
 *   3. Manage Mock Tests → /admin/mock-tests/manage
 */
export default function AdminMockTestsPage() {
  return (
    <>
      <div className="page-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-md)' }}>
          <Link href="/admin" className="btn btn-ghost btn-icon">
            <ArrowLeft size={20} />
          </Link>
          <div>
            <div className="page-title">Organize Mock Tests</div>
            <div className="page-subtitle">Configure, generate, and monitor mock examinations</div>
          </div>
        </div>
      </div>

      <div className="page-body animate-fade-in-up">
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', 
          gap: 'var(--space-xl)', 
          maxWidth: 1000 
        }}>
          {/* Manual Mock */}
          <Link href="/admin/mock-tests/manual" className="card card-interactive" style={{ textDecoration: 'none', padding: 'var(--space-xl)', textAlign: 'center' }}>
            <div style={{ 
              width: 64, 
              height: 64, 
              borderRadius: 'var(--radius-lg)', 
              background: 'linear-gradient(135deg, #667eea, #764ba2)', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center', 
              margin: '0 auto var(--space-lg)' 
            }}>
              <ClipboardList size={30} color="white" />
            </div>
            <div style={{ fontWeight: 700, fontSize: 'var(--font-size-lg)', marginBottom: 'var(--space-xs)', color: 'var(--color-text)' }}>Manual Mock Test</div>
            <div style={{ fontSize: 'var(--font-size-sm)', color: 'var(--color-text-muted)' }}>
              Select existing question topics, configure rules, dynamic limits, and generate tests manually.
            </div>
          </Link>

          {/* CSV Auto Mock */}
          <Link href="/admin/mock-tests/csv" className="card card-interactive" style={{ textDecoration: 'none', padding: 'var(--space-xl)', textAlign: 'center' }}>
            <div style={{ 
              width: 64, 
              height: 64, 
              borderRadius: 'var(--radius-lg)', 
              background: 'linear-gradient(135deg, #f093fb, #f5576c)', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center', 
              margin: '0 auto var(--space-lg)' 
            }}>
              <Upload size={30} color="white" />
            </div>
            <div style={{ fontWeight: 700, fontSize: 'var(--font-size-lg)', marginBottom: 'var(--space-xs)', color: 'var(--color-text)' }}>CSV Auto Mock Test</div>
            <div style={{ fontSize: 'var(--font-size-sm)', color: 'var(--color-text-muted)' }}>
              Upload a standard CSV file with parsed questions to generate a mock test instantly.
            </div>
          </Link>

          {/* Manage Mock Tests */}
          <Link href="/admin/mock-tests/manage" className="card card-interactive" style={{ textDecoration: 'none', padding: 'var(--space-xl)', textAlign: 'center' }}>
            <div style={{ 
              width: 64, 
              height: 64, 
              borderRadius: 'var(--radius-lg)', 
              background: 'linear-gradient(135deg, #4facfe, #00f2fe)', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center', 
              margin: '0 auto var(--space-lg)' 
            }}>
              <Database size={30} color="white" />
            </div>
            <div style={{ fontWeight: 700, fontSize: 'var(--font-size-lg)', marginBottom: 'var(--space-xs)', color: 'var(--color-text)' }}>Manage Mock Tests</div>
            <div style={{ fontSize: 'var(--font-size-sm)', color: 'var(--color-text-muted)' }}>
              View and edit created tests, toggle active states, inspect questions, and track report analytics.
            </div>
          </Link>
        </div>
      </div>
    </>
  );
}
