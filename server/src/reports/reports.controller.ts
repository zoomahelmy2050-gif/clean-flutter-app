import { Body, Controller, Get, Param, Patch, Post, Query, Req, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { JwtGuard } from '../auth/jwt.guard.js';
import { AdminGuard } from '../auth/admin.guard.js';
import { ReportsService } from './reports.service.js';
import { CreateReportDto } from './dto/create-report.dto.js';
import { UpdateReportStatusDto } from './dto/update-report-status.dto.js';

type ReportStatus = 'SUBMITTED' | 'IN_PROGRESS' | 'FIXED';

@Controller('reports')
export class ReportsController {
  constructor(private reports: ReportsService) {}

  // Create a new report (authenticated user)
  @Post()
  @UseGuards(JwtGuard)
  async create(@Req() req: any, @Body() dto: CreateReportDto) {
    const userId = req.user?.sub as string;
    return this.reports.createReport(userId, dto);
  }

  // Fetch all reports (admin only), supports filters
  @Get()
  @UseGuards(JwtGuard, AdminGuard)
  async getAll(
    @Query('issueType') issueType?: string,
    @Query('status') status?: ReportStatus,
    @Query('skip') skip?: string,
    @Query('take') take?: string,
  ) {
    return this.reports.getAllReports({
      issueType: issueType || undefined,
      status: status || undefined,
      skip: skip ? Number(skip) : undefined,
      take: take ? Number(take) : undefined,
    });
  }

  // Summary endpoint for admin dashboards
  @Get('admin/summary')
  @UseGuards(JwtGuard, AdminGuard)
  async summary() {
    return this.reports.getSummary();
  }

  // Export reports (CSV or JSON)
  @Get('admin/export')
  @UseGuards(JwtGuard, AdminGuard)
  async export(@Query('format') format: 'csv' | 'json' = 'csv', @Res() res: Response) {
    const out = await this.reports.exportReports(format);
    if (format === 'json') {
      return res.json(out);
    }
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="reports.csv"');
    return res.send(out);
  }

  // Admin: get lightweight locations for map view
  @Get('admin/locations')
  @UseGuards(JwtGuard, AdminGuard)
  async locations(
    @Query('status') status?: ReportStatus,
    @Query('issueType') issueType?: string,
    @Query('limit') limit?: string,
  ) {
    return this.reports.getLocations({
      status: status || undefined,
      issueType: issueType || undefined,
      limit: limit ? Number(limit) : undefined,
    });
  }

  // Admin: distinct issue types (for filters)
  @Get('admin/issue-types')
  @UseGuards(JwtGuard, AdminGuard)
  async issueTypes() {
    return this.reports.getDistinctIssueTypes();
  }

  // Fetch current user's reports
  @Get('me')
  @UseGuards(JwtGuard)
  async getMyReports(@Req() req: any) {
    const userId = req.user?.sub as string;
    return this.reports.getReportsForUser(userId);
  }

  // Fetch reports for a specific user (admin only)
  @Get(':userId')
  @UseGuards(JwtGuard, AdminGuard)
  async getByUser(@Param('userId') userId: string) {
    return this.reports.getReportsForUser(userId);
  }

  // Update report status (admin only)
  @Patch(':id')
  @UseGuards(JwtGuard, AdminGuard)
  async updateStatus(@Param('id') id: string, @Body() body: UpdateReportStatusDto) {
    return this.reports.updateReportStatus(id, body.status as unknown as ReportStatus);
  }

}
