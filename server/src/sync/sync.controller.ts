import { Controller, Get, Post, Body, UseGuards, Req, Request } from '@nestjs/common';
import { SyncService } from './sync.service.js';
import { JwtGuard } from '../auth/jwt.guard.js';

@Controller('sync')
export class SyncController {
  constructor(private syncService: SyncService) {}

  @Get('status')
  @UseGuards(JwtGuard)
  async getSyncStatus(@Req() req: any) {
    return this.syncService.getSyncStatus(req.user.id);
  }

  @Get('pending')
  @UseGuards(JwtGuard)
  async getPendingItems(@Request() req: any) {
    return this.syncService.getPendingSyncItems(req.user.id);
  }

  @Post('queue')
  @UseGuards(JwtGuard)
  async addToQueue(@Request() req: any, @Body() data: any) {
    return this.syncService.addToSyncQueue({
      userId: req.user.id,
      ...data,
    });
  }

  @Post('process')
  @UseGuards(JwtGuard)
  async getQueue(@Request() req: any) {
    return this.syncService.processSyncQueue(req.user.id);
  }

  @Post('cleanup')
  @UseGuards(JwtGuard)
  async cleanup() {
    return this.syncService.cleanupSyncQueue();
  }
}
