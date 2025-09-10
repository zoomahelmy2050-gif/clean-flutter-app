var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
import { Body, Controller, Get, Param, Patch, Post, Query, Req, Res, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard.js';
import { AdminGuard } from '../auth/admin.guard.js';
import { ReportsService } from './reports.service.js';
import { CreateReportDto } from './dto/create-report.dto.js';
import { UpdateReportStatusDto } from './dto/update-report-status.dto.js';
let ReportsController = class ReportsController {
    reports;
    constructor(reports) {
        this.reports = reports;
    }
    // Create a new report (authenticated user)
    async create(req, dto) {
        const userId = req.user?.sub;
        return this.reports.createReport(userId, dto);
    }
    // Fetch all reports (admin only), supports filters
    async getAll(issueType, status, skip, take) {
        return this.reports.getAllReports({
            issueType: issueType || undefined,
            status: status || undefined,
            skip: skip ? Number(skip) : undefined,
            take: take ? Number(take) : undefined,
        });
    }
    // Summary endpoint for admin dashboards
    async summary() {
        return this.reports.getSummary();
    }
    // Export reports (CSV or JSON)
    async export(format = 'csv', res) {
        const out = await this.reports.exportReports(format);
        if (format === 'json') {
            return res.json(out);
        }
        res.setHeader('Content-Type', 'text/csv; charset=utf-8');
        res.setHeader('Content-Disposition', 'attachment; filename="reports.csv"');
        return res.send(out);
    }
    // Admin: get lightweight locations for map view
    async locations(status, issueType, limit) {
        return this.reports.getLocations({
            status: status || undefined,
            issueType: issueType || undefined,
            limit: limit ? Number(limit) : undefined,
        });
    }
    // Admin: distinct issue types (for filters)
    async issueTypes() {
        return this.reports.getDistinctIssueTypes();
    }
    // Fetch current user's reports
    async getMyReports(req) {
        const userId = req.user?.sub;
        return this.reports.getReportsForUser(userId);
    }
    // Fetch reports for a specific user (admin only)
    async getByUser(userId) {
        return this.reports.getReportsForUser(userId);
    }
    // Update report status (admin only)
    async updateStatus(id, body) {
        return this.reports.updateReportStatus(id, body.status);
    }
};
__decorate([
    Post(),
    UseGuards(JwtGuard),
    __param(0, Req()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, CreateReportDto]),
    __metadata("design:returntype", Promise)
], ReportsController.prototype, "create", null);
__decorate([
    Get(),
    UseGuards(JwtGuard, AdminGuard),
    __param(0, Query('issueType')),
    __param(1, Query('status')),
    __param(2, Query('skip')),
    __param(3, Query('take')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], ReportsController.prototype, "getAll", null);
__decorate([
    Get('admin/summary'),
    UseGuards(JwtGuard, AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReportsController.prototype, "summary", null);
__decorate([
    Get('admin/export'),
    UseGuards(JwtGuard, AdminGuard),
    __param(0, Query('format')),
    __param(1, Res()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], ReportsController.prototype, "export", null);
__decorate([
    Get('admin/locations'),
    UseGuards(JwtGuard, AdminGuard),
    __param(0, Query('status')),
    __param(1, Query('issueType')),
    __param(2, Query('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], ReportsController.prototype, "locations", null);
__decorate([
    Get('admin/issue-types'),
    UseGuards(JwtGuard, AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReportsController.prototype, "issueTypes", null);
__decorate([
    Get('me'),
    UseGuards(JwtGuard),
    __param(0, Req()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ReportsController.prototype, "getMyReports", null);
__decorate([
    Get(':userId'),
    UseGuards(JwtGuard, AdminGuard),
    __param(0, Param('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ReportsController.prototype, "getByUser", null);
__decorate([
    Patch(':id'),
    UseGuards(JwtGuard, AdminGuard),
    __param(0, Param('id')),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, UpdateReportStatusDto]),
    __metadata("design:returntype", Promise)
], ReportsController.prototype, "updateStatus", null);
ReportsController = __decorate([
    Controller('reports'),
    __metadata("design:paramtypes", [ReportsService])
], ReportsController);
export { ReportsController };
//# sourceMappingURL=reports.controller.js.map