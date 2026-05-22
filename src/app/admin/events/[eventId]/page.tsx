import React from 'react';
import { useParams } from 'next/navigation';

export default function AdminEventPage() {
  const params = useParams();
  return <div className="p-6">Admin Event: {params?.eventId}</div>;
}
