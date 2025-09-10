# Citizen Fix Admin Dashboard

A minimal Next.js 14 app for managing Reports.

## Setup

1. Install deps

```bash
npm i
```

2. Configure backend URL

Set env var at runtime:
- Windows PowerShell
```powershell
$env:NEXT_PUBLIC_API_BASE_URL="http://localhost:3000"; npm run dev
```
- or create `.env.local` with:
```
NEXT_PUBLIC_API_BASE_URL=http://localhost:3000
```

3. Run dev server
```bash
npm run dev
```

## Pages
- `/login` – Admin login
- `/reports` – Reports table with filters, export and status actions
- `/reports/map` – Map view using Leaflet

## Notes
- The backend must include RBAC and the new Reports Module endpoints.
- CORS: add your dev origin (http://localhost:4000) to backend `CORS_ORIGINS` env.
