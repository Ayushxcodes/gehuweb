"use client";

import React from 'react';
import { useParams } from 'next/navigation';

export default function EventChatPage() {
  const params = useParams();
  return <div className="p-6">Chat for event {params?.eventId}</div>;
}
