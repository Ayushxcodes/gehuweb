import React from 'react';
import { useParams } from 'next/navigation';

export default function StudentEventPage() {
  const params = useParams();
  return <div className="p-6">Event: {params?.eventId}</div>;
}
