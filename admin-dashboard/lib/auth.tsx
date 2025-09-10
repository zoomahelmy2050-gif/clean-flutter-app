"use client";
import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import { API_BASE } from './env';

export type AuthContextType = {
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  setToken: (t: string | null) => void;
  authHeader: () => Record<string, string>;
};

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    const saved = localStorage.getItem('admin_jwt');
    if (saved) setToken(saved);
  }, []);

  const login = async (email: string, password: string) => {
    const res = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    if (!res.ok) {
      const msg = await res.text();
      throw new Error(msg || 'Login failed');
    }
    const data = await res.json();
    const t = data?.accessToken as string;
    if (!t) throw new Error('No token');
    localStorage.setItem('admin_jwt', t);
    setToken(t);
  };

  const logout = () => {
    localStorage.removeItem('admin_jwt');
    setToken(null);
  };

  const authHeader = () => (token ? { Authorization: `Bearer ${token}` } : {});

  const value = useMemo(() => ({ token, login, logout, setToken, authHeader }), [token]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
