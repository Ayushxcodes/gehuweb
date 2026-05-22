import React from 'react';
import { useParams } from 'next/navigation';

export default function EventParticipatePage() {
  const params = useParams();
  return (
    <div className="p-6">
      Participate: event {params?.eventId} comp {params?.compId}
    </div>
  );
}
