"use client";
import React, { useEffect, useMemo, useState } from 'react';
import dynamic from 'next/dynamic';
import RequireAuth from '../../../components/RequireAuth';
import ReportsFilters from '../../../components/ReportsFilters';
import { useAuthedSWR } from '../../../lib/api';
import { LocationPoint, ReportStatus } from '../../../types';

// react-leaflet components must be dynamically imported without SSR
const MapContainer = dynamic(() => import('react-leaflet').then(m => m.MapContainer), { ssr: false });
const TileLayer = dynamic(() => import('react-leaflet').then(m => m.TileLayer), { ssr: false });
const Marker = dynamic(() => import('react-leaflet').then(m => m.Marker), { ssr: false });
const Popup = dynamic(() => import('react-leaflet').then(m => m.Popup), { ssr: false });

// Leaflet CSS
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix default icon paths in Next.js
const icon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

function toQuery(params: Record<string, string | undefined>) {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => { if (v) q.set(k, v); });
  const s = q.toString();
  return s ? `?${s}` : '';
}

export default function ReportsMapPage() {
  const [status, setStatus] = useState<ReportStatus | 'ALL'>('ALL');
  const [issueType, setIssueType] = useState<string | 'ALL'>('ALL');
  const issueTypes = useAuthedSWR<string[]>(`/reports/admin/issue-types`);

  const listQuery = useMemo(() => toQuery({
    status: status === 'ALL' ? undefined : status,
    issueType: issueType === 'ALL' ? undefined : issueType,
    limit: '2000',
  }), [status, issueType]);
  const { data: points, isLoading, error } = useAuthedSWR<LocationPoint[]>(`/reports/admin/locations${listQuery}`);

  // Default center (Cairo), adjust as needed
  const center: [number, number] = [30.0444, 31.2357];

  return (
    <RequireAuth>
      <div className="card">
        <h2>Reports Map</h2>
      </div>

      <ReportsFilters
        issueTypes={issueTypes.data || []}
        status={status}
        issueType={issueType}
        onChange={(n) => { setStatus(n.status); setIssueType(n.issueType); }}
      />

      <div className="card mt-16" style={{ height: 600 }}>
        {isLoading && <div>Loading map…</div>}
        {error && <div style={{ color: '#b91c1c' }}>{String(error)}</div>}
        {!isLoading && !error && (
          <MapContainer center={center} zoom={12} style={{ height: 560 }}>
            <TileLayer
              attribution='&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            {(points || []).map((p) => (
              <Marker key={p.id} position={[p.latitude, p.longitude]} icon={icon}>
                <Popup>
                  <div style={{ minWidth: 240 }}>
                    <div><b>ID:</b> {p.id}</div>
                    <div><b>Issue:</b> {p.issueType}</div>
                    <div><b>Status:</b> {p.status}</div>
                    <div><b>Created:</b> {new Date(p.createdAt).toLocaleString()}</div>
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>
        )}
      </div>
    </RequireAuth>
  );
}
