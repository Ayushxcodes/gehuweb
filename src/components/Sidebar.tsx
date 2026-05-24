"use client";

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '../app/providers/AuthProvider';
import {
  LayoutDashboard, Calendar, FileText, Bell, BookOpen, ClipboardList,
  Briefcase, Users, BarChart3, MessageSquare, Settings, LogOut, Menu, X,
  Search, Trophy, Award, Mail
} from 'lucide-react';
import { supabase } from '../utils/supabaseClient';
import './Sidebar.css';

export default function Sidebar() {
  const { user, isAdmin, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname() || '/';
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [bellCount, setBellCount] = useState<number>(0);

  useEffect(() => {
    if (isAdmin) return;
    const fetchCount = async () => {
      try {
        const { data } = await supabase.rpc('api_student_notification_badge_count');
        setBellCount(data || 0);
      } catch (err) { /* silent */ }
    };
    fetchCount();
    const interval = setInterval(fetchCount, 60000);
    return () => clearInterval(interval);
  }, [isAdmin]);

  const handleLogout = async () => {
    if (typeof window !== 'undefined' && window.confirm('Are you sure you want to logout?')) {
      await logout();
      router.push('/auth/login');
    }
  };

  const studentLinks: any[] = [
    { section: 'Core' },
    { to: '/student/dashboard', icon: LayoutDashboard, label: 'Home', end: true },
    { to: '/student/notifications', icon: Bell, label: 'Notifications', badge: bellCount },
    { to: '/student/mail', icon: Mail, label: 'Mail' },

    { section: 'Academics' },
    { to: '/student/mock-tests', icon: ClipboardList, label: 'Mock Test' },
    { to: '/student/practice', icon: BookOpen, label: 'Practice' },
    { to: '/student/results', icon: Trophy, label: 'Result' },
    { to: '/student/notices', icon: FileText, label: 'Notice Board' },

    { section: 'Career & Events' },
    { to: '/student/events', icon: Calendar, label: 'Events' },
    { to: '/student/achievements', icon: Award, label: 'Achievements' },
    { to: '/student/resume', icon: Briefcase, label: 'Resume' },
    { to: '/student/feedback', icon: MessageSquare, label: 'Resume Feedback' },
  ];

  const adminLinks: any[] = [
    { section: 'Core' },
    { to: '/admin', icon: LayoutDashboard, label: 'Dashboard', end: true },

    { section: 'Modules' },
    { to: '/admin/organize', icon: ClipboardList, label: 'Organize' },
    { to: '/admin/events', icon: Calendar, label: 'Events' },
    { to: '/admin/notices', icon: FileText, label: 'Notices' },
    { to: '/admin/reports', icon: BarChart3, label: 'Results' },

    { section: 'People' },
    { to: '/admin/student-search', icon: Search, label: 'Search Students' },
    { to: '/admin/students', icon: Users, label: 'Students' },
    { to: '/admin/feedback', icon: MessageSquare, label: 'Feedback' },
  ];

  const links = isAdmin ? adminLinks : studentLinks;

  const initials = (user?.name || user?.profileState?.name || user?.email)?.split?.(' ')?.map((n: string) => n[0])?.join?.('')?.toUpperCase?.()?.slice(0, 2) || (user?.email?.[0]?.toUpperCase() || '?');

  const isLinkActive = (to: string, end?: boolean) => {
    if (!to) return false;
    if (end) return pathname === to;
    return pathname === to || pathname.startsWith(to + '/') || pathname.startsWith(to);
  };

  return (
    <>
      <button
        className="sidebar-mobile-toggle"
        onClick={() => setMobileOpen(!mobileOpen)}
        aria-label="Toggle menu"
      >
        {mobileOpen ? <X size={22} /> : <Menu size={22} />}
      </button>

      {mobileOpen && (
        <div className="sidebar-overlay" onClick={() => setMobileOpen(false)} />
      )}

      <aside className={`sidebar ${collapsed ? 'sidebar-collapsed' : ''} ${mobileOpen ? 'sidebar-mobile-open' : ''}`}>
        <div className="sidebar-logo">
          <div className="sidebar-logo-icon">G</div>
          {!collapsed && <span className="sidebar-logo-text">GEHU Connect</span>}
        </div>

        <nav className="sidebar-nav">
          {links.map((link, i) => {
            if (link.section) {
              return !collapsed ? (
                <div key={`section-${link.section}`} className="sidebar-section-label">{link.section}</div>
              ) : <div key={`section-${link.section}`} style={{ height: 16 }} />;
            }
            const Icon = link.icon;
            const active = isLinkActive(link.to, link.end);
            return (
              <Link key={link.to} href={link.to} onClick={() => setMobileOpen(false)} className={`sidebar-link ${active ? 'sidebar-link-active' : ''}`}>
                <div style={{ position: 'relative', display: 'inline-flex' }}>
                  <Icon size={18} />
                  {link.badge > 0 && (
                    <span style={{
                      position: 'absolute', top: -5, right: -7,
                      background: 'var(--color-error)', color: '#fff',
                      fontSize: 9, fontWeight: 700, borderRadius: 10,
                      padding: '1px 5px', minWidth: 14, textAlign: 'center',
                      lineHeight: '14px'
                    }}>{link.badge > 99 ? '99+' : link.badge}</span>
                  )}
                </div>
                {!collapsed && <span>{link.label}</span>}
              </Link>
            );
          })}
        </nav>

        <div className="sidebar-footer">
          <Link href="/settings" onClick={() => setMobileOpen(false)} className={`sidebar-link ${isLinkActive('/settings') ? 'sidebar-link-active' : ''}`}>
            <Settings size={20} />
            {!collapsed && <span>Settings</span>}
          </Link>

          <div className="sidebar-user">
            <div className="avatar avatar-sm">{initials}</div>
            {!collapsed && (
              <div className="sidebar-user-info">
                <div className="sidebar-user-name">{user?.profileState?.name || user?.name || 'User'}</div>
                <div className="sidebar-user-role">{user?.identity?.account_type || 'Student'}</div>
              </div>
            )}
            <button className="sidebar-logout" onClick={handleLogout} title="Sign Out">
              <LogOut size={18} />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
