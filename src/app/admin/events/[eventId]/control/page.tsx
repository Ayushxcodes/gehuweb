import React from 'react';
import { useParams } from 'next/navigation';

export default function AdminEventControlPanelPage() {
  const params = useParams();
  return <div className="p-6">Admin Control Panel for event {params?.eventId}</div>;
}
