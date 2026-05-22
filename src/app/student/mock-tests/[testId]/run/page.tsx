"use client";

import React from 'react';
import { useParams } from 'next/navigation';

export default function MockTestRunnerPage() {
  const params = useParams();
  return (
    <div className="p-6">Running Mock Test: {params?.testId || 'unknown'}</div>
  );
}
