export type ReportStatus = 'SUBMITTED' | 'IN_PROGRESS' | 'FIXED';

export interface Report {
  id: string;
  userId: string;
  issueType: string;
  description: string;
  photoUrl?: string | null;
  latitude: number;
  longitude: number;
  status: ReportStatus;
  createdAt: string;
  updatedAt: string;
}

export interface LocationPoint {
  id: string;
  issueType: string;
  status: ReportStatus;
  latitude: number;
  longitude: number;
  createdAt: string;
}
