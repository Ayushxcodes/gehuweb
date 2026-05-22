import React from 'react';
import { useParams } from 'next/navigation';

export default function ManageCompetitionsPage() {
  const params = useParams();
  return <div className="p-6">Competitions for event {params?.eventId}</div>;
}
