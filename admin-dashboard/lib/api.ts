"use client";
import useSWR, { SWRConfiguration } from 'swr';
import { API_BASE } from './env';
import { useAuth } from './auth';

export function useAuthedFetcher() {
  const { token } = useAuth();
  const fetcher = async (path: string) => {
    const res = await fetch(`${API_BASE}${path}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      cache: 'no-store',
    });
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  };
  return fetcher;
}

export function useAuthedSWR<T = any>(path: string | null, config?: SWRConfiguration<T>) {
  const fetcher = useAuthedFetcher();
  return useSWR<T>(path, path ? fetcher : null, { revalidateOnFocus: false, ...config });
}

export async function patchReportStatus(reportId: string, status: 'IN_PROGRESS' | 'FIXED', token: string) {
  const res = await fetch(`${API_BASE}/reports/${reportId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ status }),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}
