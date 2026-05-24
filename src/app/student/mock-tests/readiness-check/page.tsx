"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, CheckCircle2, Loader2, Monitor, RefreshCw, ShieldAlert, Video } from "lucide-react";
import { supabase } from "../../../../utils/supabaseClient";

interface MockTestSummary {
  test_id: string;
  title: string;
  start_at: string;
  duration_minutes: number;
  requires_web_proctoring: boolean;
}

export default function MockReadinessCheckPage() {
  const router = useRouter();

  const [testId, setTestId] = useState("");
  const [loading, setLoading] = useState(false);
  const [checking, setChecking] = useState(false);
  const [test, setTest] = useState<MockTestSummary | null>(null);
  const [cameraOk, setCameraOk] = useState(false);
  const [micOk, setMicOk] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    setTestId(params.get("testId") || "");
  }, []);

  useEffect(() => {
    if (!testId) return;

    let active = true;
    async function loadTest() {
      try {
        setLoading(true);
        const { data, error } = await supabase
          .schema("mocks")
          .from("mock_tests")
          .select("test_id, title, start_at, duration_minutes, requires_web_proctoring")
          .eq("test_id", testId)
          .maybeSingle();

        if (error) throw error;
        if (active) setTest(data as MockTestSummary | null);
      } catch (err: any) {
        console.error("Failed to load mock test for readiness check:", err);
        if (active) setMessage(err?.message || "Could not load this mock test.");
      } finally {
        if (active) setLoading(false);
      }
    }

    loadTest();
    return () => {
      active = false;
    };
  }, [testId]);

  async function runHardwareCheck() {
    if (!testId) {
      setMessage("Open this check from a mock test card so the test ID is attached.");
      return;
    }

    if (!navigator.mediaDevices?.getUserMedia) {
      setCameraOk(false);
      setMicOk(false);
      setMessage("This browser does not expose camera/microphone checks. Try Chrome or Edge on desktop.");
      return;
    }

    setChecking(true);
    setMessage(null);

    let localCameraOk = false;
    let localMicOk = false;
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
      localCameraOk = stream.getVideoTracks().length > 0;
      localMicOk = stream.getAudioTracks().length > 0;
      stream.getTracks().forEach((track) => track.stop());

      setCameraOk(localCameraOk);
      setMicOk(localMicOk);

      const { error } = await supabase
        .schema("mocks")
        .rpc("api_student_mark_mock_hardware_ready", {
          p_test_id: testId,
          p_camera_ok: localCameraOk,
          p_mic_ok: localMicOk,
          p_user_agent: navigator.userAgent,
        });

      if (error) throw error;
      setMessage("Hardware verified. You can now return to the mock list and enter the runner.");
    } catch (err: any) {
      setCameraOk(localCameraOk);
      setMicOk(localMicOk);
      setMessage(err?.message || "Camera or microphone permission was denied.");
    } finally {
      setChecking(false);
    }
  }

  const ready = cameraOk && micOk;

  return (
    <div style={{ maxWidth: 860, margin: "0 auto", paddingBottom: 100 }}>
      <div className="page-header" style={{ marginBottom: "var(--space-lg)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "var(--space-md)" }}>
          <Link href="/student/mock-tests" className="btn btn-ghost btn-icon">
            <ArrowLeft size={20} />
          </Link>
          <div>
            <div className="page-title">Mock System Readiness</div>
            <div className="page-subtitle">Verify camera and microphone before entering a proctored exam.</div>
          </div>
        </div>
      </div>

      <div className="card animate-fade-in-up" style={{ padding: "var(--space-xl)", display: "flex", flexDirection: "column", gap: "var(--space-lg)" }}>
        {loading ? (
          <div style={{ display: "flex", alignItems: "center", gap: 10, color: "var(--color-text-secondary)" }}>
            <RefreshCw className="spin" size={18} /> Loading exam context...
          </div>
        ) : test ? (
          <div style={{ display: "flex", justifyContent: "space-between", gap: "var(--space-md)", flexWrap: "wrap" }}>
            <div>
              <h2 className="card-title" style={{ fontSize: "var(--font-size-xl)" }}>{test.title}</h2>
              <div className="card-subtitle">
                Starts {new Date(test.start_at).toLocaleString()} | Duration {test.duration_minutes} minutes
              </div>
            </div>
            <span className={test.requires_web_proctoring ? "badge badge-error" : "badge badge-success"}>
              {test.requires_web_proctoring ? "Proctored" : "Standard"}
            </span>
          </div>
        ) : (
          <div style={{ display: "flex", alignItems: "center", gap: 10, color: "var(--color-warning)" }}>
            <ShieldAlert size={18} /> No test context found. Return to the mock list and open readiness from a card.
          </div>
        )}

        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: "var(--space-md)" }}>
          <div className="card" style={{ border: cameraOk ? "1px solid rgba(16,185,129,0.35)" : "1px solid var(--color-border)", background: "var(--color-bg-hover)" }}>
            <Video size={24} style={{ color: cameraOk ? "#10b981" : "var(--color-text-muted)" }} />
            <div style={{ fontWeight: 800, marginTop: 8 }}>Camera</div>
            <div style={{ color: cameraOk ? "#10b981" : "var(--color-text-muted)", fontSize: "var(--font-size-sm)" }}>
              {cameraOk ? "Detected and allowed" : "Not verified yet"}
            </div>
          </div>

          <div className="card" style={{ border: micOk ? "1px solid rgba(16,185,129,0.35)" : "1px solid var(--color-border)", background: "var(--color-bg-hover)" }}>
            <Monitor size={24} style={{ color: micOk ? "#10b981" : "var(--color-text-muted)" }} />
            <div style={{ fontWeight: 800, marginTop: 8 }}>Microphone</div>
            <div style={{ color: micOk ? "#10b981" : "var(--color-text-muted)", fontSize: "var(--font-size-sm)" }}>
              {micOk ? "Detected and allowed" : "Not verified yet"}
            </div>
          </div>
        </div>

        {message && (
          <div style={{ padding: "12px 14px", borderRadius: 10, background: ready ? "rgba(16,185,129,0.12)" : "rgba(245,158,11,0.12)", color: ready ? "#10b981" : "#f59e0b", fontWeight: 700 }}>
            {message}
          </div>
        )}

        <div style={{ display: "flex", gap: "var(--space-sm)", flexWrap: "wrap" }}>
          <button className="btn btn-primary" onClick={runHardwareCheck} disabled={checking || !testId}>
            {checking ? <Loader2 className="spin" size={18} /> : <CheckCircle2 size={18} />}
            Run Camera and Mic Check
          </button>
          <button className="btn btn-secondary" onClick={() => router.push("/student/mock-tests")}>
            Back to Mock List
          </button>
          {ready && testId && (
            <button className="btn btn-success" onClick={() => router.push(`/student/mock-tests/${testId}/run`)}>
              Enter Runner
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
