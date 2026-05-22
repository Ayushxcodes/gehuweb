"use client";

import React from "react";
import Sidebar from "../../components/Sidebar";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="layout">
      <Sidebar />
      <main className="layout-content">{children}</main>
    </div>
  );
}
