"use client";

import React from 'react';
import { useParams } from 'next/navigation';

export default function NoticeDetailPage() {
  const params = useParams();
  return <div className="p-6">Notice: {params?.id}</div>;
}
