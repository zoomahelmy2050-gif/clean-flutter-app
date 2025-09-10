"use client";
import React from 'react';
import { ReportStatus } from '../types';

export default function ReportsFilters({
  issueTypes,
  status,
  issueType,
  onChange,
}: {
  issueTypes: string[];
  status: ReportStatus | 'ALL';
  issueType: string | 'ALL';
  onChange: (next: { status: ReportStatus | 'ALL'; issueType: string | 'ALL' }) => void;
}) {
  return (
    <div className="card mt-16">
      <div className="filters">
        <label>Status</label>
        <select
          className="select"
          value={status}
          onChange={(e) => onChange({ status: e.target.value as any, issueType })}
        >
          <option value="ALL">All</option>
          <option value="SUBMITTED">Submitted</option>
          <option value="IN_PROGRESS">In Progress</option>
          <option value="FIXED">Fixed</option>
        </select>

        <label>Issue Type</label>
        <select
          className="select"
          value={issueType}
          onChange={(e) => onChange({ status, issueType: e.target.value as any })}
        >
          <option value="ALL">All</option>
          {issueTypes.map((it) => (
            <option key={it} value={it}>{it}</option>
          ))}
        </select>
      </div>
    </div>
  );
}
