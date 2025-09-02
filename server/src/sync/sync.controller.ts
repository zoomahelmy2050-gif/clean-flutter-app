import { Controller, Get, Post, Body, UseGuards, Req } from '@nestjs/common';
import { SyncService } from './sync.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('sync')
export class SyncController {
  constructor(private syncService: SyncService) {}

  @Get('status')
  @UseGuards(JwtAuthGuard)
  async getSyncStatus(@Req() req) {
    return this.syncService.getSyncStatus(req.user.id);
  }

  @Get('pending')
  @UseGuards(JwtAuthGuard)
  async getPendingItems(@Req() req) {
    return this.syncService.getPendingSyncItems(req.user.id);
  }

  @Post('queue')
  @UseGuards(JwtAuthGuard)
  async addToQueue(@Req() req, @Body() data: any) {
    return this.syncService.addToSyncQueue({
      userId: req.user.id,
      ...data,
    });
  }

  @Post('process')
  @UseGuards(JwtAuthGuard)
  async processQueue(@Req() req) {
    return this.syncService.processSyncQueue(req.user.id);
  }

  @Post('cleanup')
  @UseGuards(JwtAuthGuard)
  async cleanup() {
    return this.syncService.cleanupSyncQueue();
  }
}
