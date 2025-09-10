"use client";
import React, { useMemo, useState } from 'react';
import RequireAuth from '../../components/RequireAuth';
import ReportsFilters from '../../components/ReportsFilters';
import { useAuthedSWR } from '../../lib/api';
import { useAuth } from '../../lib/auth';
import { API_BASE } from '../../lib/env';
import { Report, ReportStatus } from '../../types';
import { patchReportStatus } from '../../lib/api';

function toQuery(params: Record<string, string | undefined>) {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => {
    if (v) q.set(k, v);
  });
  const s = q.toString();
  return s ? `?${s}` : '';
}

export default function ReportsPage() {
  const { token } = useAuth();
  const [status, setStatus] = useState<ReportStatus | 'ALL'>('ALL');
  const [issueType, setIssueType] = useState<string | 'ALL'>('ALL');

  const filters = useMemo(() => ({ status, issueType }), [status, issueType]);

  const issueTypes = useAuthedSWR<string[]>(`/reports/admin/issue-types`);
  const listQuery = useMemo(() => toQuery({
    status: status === 'ALL' ? undefined : status,
    issueType: issueType === 'ALL' ? undefined : issueType,
  }), [status, issueType]);
  const { data: reports, mutate, isLoading, error } = useAuthedSWR<Report[]>(`/reports${listQuery}`);

  const onFiltersChange = (next: { status: ReportStatus | 'ALL'; issueType: string | 'ALL' }) => {
    setStatus(next.status);
    setIssueType(next.issueType);
  };

  const actionLabel = (s: ReportStatus) => {
    if (s === 'SUBMITTED') return 'Start';
    if (s === 'IN_PROGRESS') return 'Mark Fixed';
    return 'Done';
  };

  const nextStatus = (s: ReportStatus): ReportStatus | null => {
    if (s === 'SUBMITTED') return 'IN_PROGRESS';
    if (s === 'IN_PROGRESS') return 'FIXED';
    return null;
  };

  const onUpdateStatus = async (id: string, s: ReportStatus) => {
    if (!token) return;
    const ns = nextStatus(s);
    if (!ns) return;
    await patchReportStatus(id, ns, token);
    await mutate();
  };

  const download = async (format: 'csv' | 'json') => {
    if (!token) return;
    const url = `${API_BASE}/reports/admin/export?format=${format}`;
    const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
    if (!res.ok) {
      alert(await res.text());
      return;
    }
    if (format === 'json') {
      const blob = new Blob([JSON.stringify(await res.json(), null, 2)], { type: 'application/json' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = 'reports.json';
      link.click();
      return;
    }
    const text = await res.text();
    const blob = new Blob([text], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'reports.csv';
    link.click();
  };

  return (
    <RequireAuth>
      <div className="card">
        <h2>Reports</h2>
        <div className="mt-12 flex gap-8">
          <button className="button" onClick={() => download('csv')}>Export CSV</button>
          <button className="button secondary" onClick={() => download('json')}>Export JSON</button>
        </div>
      </div>

      <ReportsFilters
        issueTypes={issueTypes.data || []}
        status={filters.status}
        issueType={filters.issueType}
        onChange={onFiltersChange}
      />

      <div className="card mt-16">
        {isLoading && <div>Loading...</div>}
        {error && <div style={{ color: '#b91c1c' }}>{String(error)}</div>}
        {!isLoading && !error && (
          <table className="table">
            <thead>
              <tr>
                <th>ID</th>
                <th>User</th>
                <th>Issue</th>
                <th>Description</th>
                <th>Location</th>
                <th>Status</th>
                <th>Created</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {(reports || []).map(r => (
                <tr key={r.id}>
                  <td title={r.id}>{r.id.slice(0, 8)}…</td>
                  <td title={r.userId}>{r.userId.slice(0, 8)}…</td>
                  <td>{r.issueType}</td>
                  <td>{r.description}</td>
                  <td>{r.latitude.toFixed(4)}, {r.longitude.toFixed(4)}</td>
                  <td>{r.status}</td>
                  <td>{new Date(r.createdAt).toLocaleString()}</td>
                  <td>
                    <button
                      className="button"
                      disabled={!nextStatus(r.status)}
                      onClick={() => onUpdateStatus(r.id, r.status)}
                    >{actionLabel(r.status)}</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </RequireAuth>
  );
}
