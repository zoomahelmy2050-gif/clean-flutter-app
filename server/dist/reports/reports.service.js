var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';
let ReportsService = class ReportsService {
    prisma;
    notifications;
    constructor(prisma, notifications) {
        this.prisma = prisma;
        this.notifications = notifications;
    }
    async createReport(userId, data) {
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
    async getReportsForUser(userId) {
        return this.prisma.report.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
    }
    async getAllReports(options) {
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
    async updateReportStatus(id, status) {
        const current = await this.prisma.report.findUnique({ where: { id } });
        if (!current) {
            throw new Error('Report not found');
        }
        const allowed = {
            SUBMITTED: ['IN_PROGRESS'],
            IN_PROGRESS: ['FIXED'],
            FIXED: [],
        };
        const can = allowed[current.status].includes(status);
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
    async getById(id) {
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
            byStatus: byStatus.map((r) => ({ status: r.status, count: r._count._all })),
            byIssue: byIssue.map((r) => ({ issueType: r.issueType, count: r._count._all })),
        };
    }
    async exportReports(format = 'csv') {
        const rows = await this.prisma.report.findMany({
            orderBy: { createdAt: 'desc' },
        });
        if (format === 'json')
            return rows;
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
        const escape = (val) => {
            if (val === null || val === undefined)
                return '';
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
    async getLocations(options) {
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
        return rows.map((r) => r.issueType).filter((v) => Boolean(v));
    }
};
ReportsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService, NotificationsService])
], ReportsService);
export { ReportsService };
//# sourceMappingURL=reports.service.js.map