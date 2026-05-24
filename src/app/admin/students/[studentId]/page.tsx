"use client";

import React from 'react';
import { useParams } from 'next/navigation';

export default function StudentDetailPage() {
  const params = useParams();
  return <div className="p-6">Student: {params?.studentId}</div>;
}
