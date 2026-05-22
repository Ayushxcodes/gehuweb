import React from 'react';
import { useParams } from 'next/navigation';

export default function CompetitionControlPage() {
  const params = useParams();
  return <div className="p-6">Competition Control: {params?.compId} (event {params?.eventId})</div>;
}
