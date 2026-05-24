"use client";

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../../providers/AuthProvider';
import { supabase } from '../../../utils/supabaseClient';
import {
  Calendar, FileText, BookOpen, ClipboardList, Briefcase,
  Trophy, Bell, ChevronRight, ChevronLeft, Sparkles
} from 'lucide-react';

export default function StudentDashboardPage() {
  const { user, profileState, loading: authLoading } = useAuth();
  const [currentSlide, setCurrentSlide] = useState(0);
  const dashboardQuery = useQuery({
    queryKey: ['student-dashboard', user?.id || 'guest'],
    enabled: !authLoading && !!user,
    queryFn: async ({ signal }) => {
      const [badgeResult, eventsResult] = await Promise.all([
        supabase
          .rpc('api_student_notification_badge_count')
          .abortSignal(signal),
        supabase
          .rpc('api_student_event_feed', {
            p_limit: 10,
            p_before_start_at: null,
            p_before_event_id: null
          })
          .abortSignal(signal)
      ]);

      if (badgeResult.error) throw badgeResult.error;
      if (eventsResult.error) throw eventsResult.error;

      const liveEvents = (eventsResult.data || []).filter((e: any) => e.is_live);

      return {
        unreadCount: badgeResult.data || 0,
        events: liveEvents.slice(0, 10),
      };
    },
  });

  const unreadCount = dashboardQuery.data?.unreadCount || 0;
  const events = dashboardQuery.data?.events || [];
  const loading = authLoading || (dashboardQuery.isPending && !dashboardQuery.data);

  const firstName = profileState?.name?.split(' ')[0] || user?.name?.split(' ')[0] || 'Student';

  // Exact 6 action rows from Vercel deployed client DashboardPage.jsx
  const actionRows = [
    { to: '/student/mock-tests', icon: ClipboardList, label: 'Mock Test', gradient: 'linear-gradient(135deg, #0ea5e9 0%, #3b82f6 100%)', desc: 'Attempt active aptitude tests' },
    { to: '/student/practice', icon: BookOpen, label: 'Practice', gradient: 'linear-gradient(135deg, #10b981 0%, #059669 100%)', desc: 'Sharpen your coding skills' },
    { to: '/student/results', icon: Trophy, label: 'Result', gradient: 'linear-gradient(135deg, #8b5cf6 0%, #6d28d9 100%)', desc: 'View your performance analytics' },
    { to: '/student/resume', icon: Briefcase, label: 'Resume', gradient: 'linear-gradient(135deg, #ec4899 0%, #be185d 100%)', desc: 'Build and refine your CV' },
    { to: '/student/notices', icon: FileText, label: 'Notice Board', gradient: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)', desc: 'Campus announcements & updates' },
    { to: '/student/events', icon: Calendar, label: 'Events', gradient: 'linear-gradient(135deg, #f43f5e 0%, #e11d48 100%)', desc: 'Register for upcoming events' },
  ];

  // Build carousel items
  const carouselItems: any[] = [];
  if (events.length === 0) {
    carouselItems.push({ type: 'welcome', title: 'Welcome to GEHU Connect', subtitle: 'Your all-in-one campus ecosystem.' });
  } else {
    events.forEach((e: any) => carouselItems.push({ type: 'event', id: e.event_id, title: e.title, subtitle: e.subtitle || '', bannerUrl: e.banner_url }));
  }

  const nextSlide = () => setCurrentSlide(prev => (prev + 1) % carouselItems.length);
  const prevSlide = () => setCurrentSlide(prev => (prev - 1 + carouselItems.length) % carouselItems.length);

  useEffect(() => {
    if (carouselItems.length <= 1) return;
    const timer = setInterval(nextSlide, 7000);
    return () => clearInterval(timer);
  }, [carouselItems.length]);

  return (
    <>
      {/* BRANDING HEADER (Matching Vercel page-header exactly) */}
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-xl)' }}>
        <div>
          <div style={{ fontSize: 'var(--font-size-xs)', fontWeight: 800, letterSpacing: '0.1em', color: 'var(--color-accent)', textTransform: 'uppercase', display: 'flex', alignItems: 'center', gap: 4 }}>
            <Sparkles size={14} /> GEHU CONNECT
          </div>
          <div className="page-subtitle" style={{ marginTop: 4, fontWeight: 500, color: 'var(--color-text-primary)' }}>Student Dashboard</div>
        </div>
        <Link href="/student/notifications" className="btn btn-ghost btn-icon" style={{ position: 'relative', background: 'rgba(255,255,255,0.05)', backdropFilter: 'blur(10px)', border: '1px solid rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: 40, height: 40, borderRadius: '50%' }}>
          <Bell size={20} color="var(--color-text-primary)" />
          {unreadCount > 0 && (
            <span style={{ position: 'absolute', top: -4, right: -4, minWidth: 20, height: 20, borderRadius: 10, background: 'var(--color-error)', color: 'white', fontSize: 11, fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '0 4px', boxShadow: '0 2px 8px rgba(239, 68, 68, 0.5)' }}>
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </Link>
      </div>

      <div className="page-body animate-fade-in-up" style={{ paddingBottom: 'var(--space-3xl)' }}>
        <div style={{ fontSize: 'var(--font-size-2xl)', fontWeight: 800, marginBottom: 'var(--space-xl)', color: 'var(--color-text-primary)', letterSpacing: '-0.02em' }}>
          Welcome back, <span style={{ color: 'var(--color-accent)' }}>{firstName}</span> ðŸ‘‹
        </div>

        {/* Premium Glass Banner Carousel (1:1 Vercel Implementation) */}
        {carouselItems.length > 0 && (
          <div style={{ position: 'relative', marginBottom: 'var(--space-2xl)', borderRadius: 'var(--radius-xl)', overflow: 'hidden', height: 220, background: 'var(--color-bg-elevated)', boxShadow: 'var(--shadow-lg)', border: '1px solid var(--color-border)' }}>
            {carouselItems.map((item, i) => (
              <div key={i} style={{
                position: 'absolute', inset: 0, transition: 'all 0.6s cubic-bezier(0.16, 1, 0.3, 1)',
                opacity: i === currentSlide ? 1 : 0,
                transform: i === currentSlide ? 'scale(1)' : 'scale(1.05)',
                pointerEvents: i === currentSlide ? 'auto' : 'none',
              }}>
                {item.type === 'event' ? (
                  <Link href={`/student/events/${item.id}`} style={{ display: 'block', height: '100%', textDecoration: 'none' }}>
                    <div style={{ height: '100%', background: item.bannerUrl ? `url(${item.bannerUrl}) center/cover` : 'var(--gradient-card)', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', padding: 'var(--space-xl)' }}>
                      <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to top, rgba(15, 17, 26, 0.95) 0%, rgba(15, 17, 26, 0.2) 100%)' }} />
                      <div style={{ position: 'relative', zIndex: 2 }}>
                        <div style={{ color: 'white', fontWeight: 800, fontSize: 'var(--font-size-2xl)', letterSpacing: '-0.02em', textShadow: '0 2px 8px rgba(0,0,0,0.5)' }}>{item.title}</div>
                        {item.subtitle && <div style={{ color: 'rgba(255,255,255,0.85)', fontSize: 'var(--font-size-sm)', marginTop: 4, fontWeight: 500 }}>{item.subtitle}</div>}
                      </div>
                    </div>
                  </Link>
                ) : (
                  <div style={{ height: '100%', background: 'radial-gradient(circle at 100% 0%, rgba(34, 211, 238, 0.2) 0%, transparent 50%), var(--gradient-card)', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', color: 'white', padding: 'var(--space-xl)', textAlign: 'center' }}>
                    <div style={{ fontSize: 'var(--font-size-2xl)', fontWeight: 800, letterSpacing: '-0.02em' }}>{item.title}</div>
                    <div style={{ fontSize: 'var(--font-size-base)', opacity: 0.8, marginTop: 8, fontWeight: 500 }}>{item.subtitle}</div>
                  </div>
                )}
              </div>
            ))}

            {/* Nav arrows & dots */}
            {carouselItems.length > 1 && (
              <>
                <button onClick={prevSlide} style={{ position: 'absolute', left: 16, top: '50%', transform: 'translateY(-50%)', background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(8px)', borderRadius: '50%', width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: 'white', zIndex: 10, transition: 'all 0.2s', border: 'none' }}><ChevronLeft size={20} /></button>
                <button onClick={nextSlide} style={{ position: 'absolute', right: 16, top: '50%', transform: 'translateY(-50%)', background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(8px)', borderRadius: '50%', width: 40, height: 40, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: 'white', zIndex: 10, transition: 'all 0.2s', border: 'none' }}><ChevronRight size={20} /></button>
                <div style={{ position: 'absolute', bottom: 16, left: '50%', transform: 'translateX(-50%)', display: 'flex', gap: 8, zIndex: 10 }}>
                  {carouselItems.map((_, i) => (
                    <button key={i} onClick={() => setCurrentSlide(i)} style={{ width: i === currentSlide ? 24 : 8, height: 8, borderRadius: 4, background: i === currentSlide ? 'var(--color-accent)' : 'rgba(255,255,255,0.4)', border: 'none', cursor: 'pointer', transition: 'all 0.3s cubic-bezier(0.16, 1, 0.3, 1)', padding: 0 }} />
                  ))}
                </div>
              </>
            )}
          </div>
        )}

        {/* 6 Action Rows - Levitated Glassmorphism Grid */}
        {loading ? (
          <div className="grid-2">
            {[1,2,3,4,5,6].map(i => <div key={i} className="skeleton" style={{ height: 90 }} />)}
          </div>
        ) : (
          <div className="grid-2">
            {actionRows.map(row => (
              <Link key={row.to} href={row.to} className="card card-interactive" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center', gap: 'var(--space-lg)', padding: 'var(--space-lg)', border: '1px solid rgba(255,255,255,0.04)', background: 'rgba(22, 25, 37, 0.6)' }}>
                <div style={{ width: 56, height: 56, borderRadius: 'var(--radius-lg)', background: row.gradient, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, boxShadow: '0 8px 16px rgba(0,0,0,0.3)', position: 'relative' }}>
                  <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg, rgba(255,255,255,0.2) 0%, transparent 100%)', borderRadius: 'var(--radius-lg)' }} />
                  <row.icon size={28} color="white" style={{ position: 'relative', zIndex: 2 }} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 800, fontSize: 'var(--font-size-lg)', color: 'var(--color-text-primary)', letterSpacing: '-0.01em', marginBottom: 2 }}>{row.label}</div>
                  <div style={{ fontSize: 'var(--font-size-xs)', color: 'var(--color-text-muted)', fontWeight: 500 }}>{row.desc}</div>
                </div>
                <div style={{ width: 32, height: 32, borderRadius: '50%', background: 'rgba(255,255,255,0.03)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <ChevronRight size={18} color="var(--color-text-secondary)" />
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
