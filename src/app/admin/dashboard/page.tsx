"use client";

import React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ClipboardList, BarChart3, FileText, MessageSquare, Search, Calendar, LogOut } from 'lucide-react';
import { useAuth } from '../../providers/AuthProvider';

export default function AdminDashboardPage() {
  const { logout } = useAuth();
  const router = useRouter();

  const handleLogout = () => { logout(); router.replace('/auth/login'); };

  const cards = [
    { to: '/admin/organize', icon: ClipboardList, label: 'Organize', sub: 'Create Mock Tests', gradient: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)' },
    { to: '/admin/reports', icon: BarChart3, label: 'Results', sub: 'Publish & Export', gradient: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)' },
    { to: '/admin/notices', icon: FileText, label: 'Notices', sub: 'Send Announcements', gradient: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)' },
    { to: '/admin/feedback', icon: MessageSquare, label: 'Feedback', sub: 'Review Responses', gradient: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)' },
    { to: '/admin/student-search', icon: Search, label: 'Search Students', sub: 'Search & Verify', gradient: 'linear-gradient(135deg, #fa709a 0%, #fee140 100%)' },
    { to: '/admin/appeals', icon: ClipboardList, label: 'Appeals', sub: 'Profile Verification', gradient: 'linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%)' },
    { to: '/admin/events', icon: Calendar, label: 'Events', sub: 'Create & Manage', gradient: 'linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%)' },
  ];

  return (
    <>
      <div className="page-header">
        <div>
          <div className="page-title">Admin Console</div>
          <div className="page-subtitle">GEHU Connect Management</div>
        </div>
      </div>
      <div className="page-body animate-fade-in-up">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 'var(--space-lg)' }}>
          {cards.map(card => (
            <Link key={card.to} href={card.to} className="card card-interactive" style={{ textDecoration: 'none', overflow: 'hidden', position: 'relative' }}>
              <div style={{ position: 'absolute', top: 0, right: 0, width: 100, height: 100, borderRadius: '0 0 0 100%', background: card.gradient, opacity: 0.15 }} />
              <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-lg)' }}>
                <div style={{ width: 56, height: 56, borderRadius: 'var(--radius-lg)', background: card.gradient, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <card.icon size={26} color="white" />
                </div>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 'var(--font-size-lg)', color: 'var(--color-text-primary)' }}>{card.label}</div>
                  <div style={{ fontSize: 'var(--font-size-sm)', color: 'var(--color-text-muted)', marginTop: 2 }}>{card.sub}</div>
                </div>
              </div>
            </Link>
          ))}
        </div>

        <div style={{ marginTop: 'var(--space-2xl)', textAlign: 'center' }}>
          <button className="btn btn-ghost" onClick={handleLogout} style={{ color: 'var(--color-error)' }}>
            <LogOut size={18} /> Logout
          </button>
        </div>
      </div>
    </>
  );
}

