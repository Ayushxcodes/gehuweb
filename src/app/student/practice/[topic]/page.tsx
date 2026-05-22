"use client";

import React from 'react';
import { useParams } from 'next/navigation';

export default function PracticeSessionPage() {
  const params = useParams();
  return <div className="p-6">Practice Topic: {params?.topic}</div>;
}
