import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';

type ReportStatus = 'SUBMITTED' | 'IN_PROGRESS' | 'FIXED';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService, private notifications: NotificationsService) {}

  async createReport(userId: string, data: {
    issueType: string;
    description: string;
    photoUrl?: string;
    latitude: number;
    longitude: number;
  }) {
    return this.prisma.report.create({
      data: {
        userId,
        issueType: data.issueType,
        description: data.description,
        photoUrl: data.photoUrl,
        latitude: data.latitude,
        longitude: data.longitude,
      },
    });
  }

  async getReportsForUser(userId: string) {
    return this.prisma.report.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAllReports(options?: {
    issueType?: string;
    status?: ReportStatus;
    skip?: number;
    take?: number;
  }) {
    const { issueType, status, skip = 0, take = 100 } = options || {};
    return this.prisma.report.findMany({
      where: {
        ...(issueType ? { issueType } : {}),
        ...(status ? { status } : {}),
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take,
    });
  }

  async updateReportStatus(id: string, status: ReportStatus) {
    const current = await this.prisma.report.findUnique({ where: { id } });
    if (!current) {
      throw new Error('Report not found');
    }

    const allowed: Record<ReportStatus, ReportStatus[]> = {
      SUBMITTED: ['IN_PROGRESS'],
      IN_PROGRESS: ['FIXED'],
      FIXED: [],
    };
    const can = allowed[current.status as ReportStatus].includes(status);
    if (!can) {
      throw new Error(`Invalid status transition from ${current.status} to ${status}`);
    }

    const updated = await this.prisma.report.update({
      where: { id },
      data: { status },
    });

    // Create a Notification DB record for audit/history and user inbox
    await this.prisma.notification.create({
      data: {
        userId: updated.userId,
        title: 'Report status updated',
        message: `Your report is now ${status.replace('_', ' ').toLowerCase()}.`,
        type: 'report_status',
        priority: 'normal',
        metadata: {
          reportId: updated.id,
          status,
          issueType: updated.issueType,
          latitude: updated.latitude,
          longitude: updated.longitude,
          updatedAt: updated.updatedAt,
        },
      },
    });

    // Emit real-time SSE notification
    this.notifications.notify(updated.userId, {
      type: 'report_status',
      title: 'Report status updated',
      message: `Your report is now ${status.replace('_', ' ').toLowerCase()}.`,
      data: {
        reportId: updated.id,
        status,
      },
    });

    return updated;
  }

  async getById(id: string) {
    return this.prisma.report.findUnique({ where: { id } });
  }

  async getSummary() {
    const [byStatus, byIssue] = await Promise.all([
      this.prisma.report.groupBy({
        by: ['status'],
        _count: { _all: true },
      }),
      this.prisma.report.groupBy({
        by: ['issueType'],
        _count: { _all: true },
      }),
    ]);

    return {
      byStatus: byStatus.map((r: any) => ({ status: r.status, count: r._count._all })),
      byIssue: byIssue.map((r: any) => ({ issueType: r.issueType, count: r._count._all })),
    };
  }

  async exportReports(format: 'csv' | 'json' = 'csv') {
    const rows = await this.prisma.report.findMany({
      orderBy: { createdAt: 'desc' },
    });

    if (format === 'json') return rows;

    const headers = [
      'id',
      'userId',
      'issueType',
      'description',
      'photoUrl',
      'latitude',
      'longitude',
      'status',
      'createdAt',
      'updatedAt',
    ];

    const escape = (val: any) => {
      if (val === null || val === undefined) return '';
      const s = String(val).replace(/"/g, '""');
      return /[",\n]/.test(s) ? `"${s}"` : s;
    };

    const lines = [headers.join(',')];
    for (const r of rows) {
      lines.push([
        r.id,
        r.userId,
        r.issueType,
        r.description,
        r.photoUrl ?? '',
        r.latitude,
        r.longitude,
        r.status,
        r.createdAt.toISOString(),
        r.updatedAt.toISOString(),
      ].map(escape).join(','));
    }

    return lines.join('\n');
  }

  async getLocations(options?: { status?: ReportStatus; issueType?: string; limit?: number }) {
    const { status, issueType, limit = 1000 } = options || {};
    const data = await this.prisma.report.findMany({
      where: {
        ...(status ? { status } : {}),
        ...(issueType ? { issueType } : {}),
      },
      select: {
        id: true,
        issueType: true,
        status: true,
        latitude: true,
        longitude: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
    return data;
  }

  async getDistinctIssueTypes() {
    const rows = await this.prisma.report.findMany({
      select: { issueType: true },
      distinct: ['issueType'],
      orderBy: { issueType: 'asc' },
    });
    return rows.map((r: { issueType: string | null }) => r.issueType).filter((v): v is string => Boolean(v));
  }
}
