"use client";

import React from 'react';
import { useParams } from 'next/navigation';

export default function ResumeBuilderEditPage() {
  const params = useParams();
  return <div className="p-6">Edit Resume: {params?.id}</div>;
}
