"use client";
import React, { useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '../lib/auth';

export default function RequireAuth({ children }: { children: React.ReactNode }) {
  const { token } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!token) {
      router.push('/login');
    }
  }, [token, router]);

  if (!token) {
    return (
      <div className="card">
        <h2>Authentication required</h2>
        <p className="mt-12">Please <Link href="/login">login</Link> to access this page.</p>
      </div>
    );
  }

  return <>{children}</>;
}
