import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller.js';
import { ReportsService } from './reports.service.js';
import { PrismaModule } from '../prisma/prisma.module.js';
import { AuthModule } from '../auth/auth.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';
import { AdminGuard } from '../auth/admin.guard.js';

@Module({
  imports: [PrismaModule, AuthModule, NotificationsModule],
  controllers: [ReportsController],
  providers: [ReportsService, AdminGuard],
  exports: [ReportsService],
})
export class ReportsModule {}
