"use client";
import Link from 'next/link';
import React from 'react';
import { useAuth } from '../lib/auth';

export default function Header() {
  const { token, logout } = useAuth();
  return (
    <header className="header">
      <div style={{ fontWeight: 700 }}>Citizen Fix Admin</div>
      <nav className="nav">
        <Link href="/">Home</Link>
        <Link href="/reports">Reports</Link>
        <Link href="/reports/map">Map</Link>
      </nav>
      <div style={{ marginLeft: 'auto' }}>
        {token ? (
          <button className="button secondary" onClick={logout}>Logout</button>
        ) : (
          <Link className="button" href="/login">Login</Link>
        )}
      </div>
    </header>
  );
}
