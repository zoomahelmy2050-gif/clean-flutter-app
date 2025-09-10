"use client";
import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '../../lib/auth';

export default function LoginPage() {
  const { login } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login(email, password);
      router.push('/reports');
    } catch (err: any) {
      setError(err?.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card" style={{ maxWidth: 420, margin: '48px auto' }}>
      <h2>Admin Login</h2>
      <form onSubmit={onSubmit} className="mt-16">
        <div className="mt-12">
          <label>Email</label>
          <input className="input" type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="admin@example.com" required />
        </div>
        <div className="mt-12">
          <label>Password</label>
          <input className="input" type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="********" required />
        </div>
        {error && <div className="mt-12" style={{ color: '#b91c1c' }}>{error}</div>}
        <div className="mt-16">
          <button className="button" type="submit" disabled={loading}>{loading ? 'Signing in...' : 'Login'}</button>
        </div>
      </form>
    </div>
  );
}
