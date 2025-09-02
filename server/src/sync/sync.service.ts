import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SyncService {
  private readonly logger = new Logger(SyncService.name);

  constructor(private prisma: PrismaService) {}

  // Get pending sync items for a user
  async getPendingSyncItems(userId: string) {
    return this.prisma.syncQueue.findMany({
      where: {
        userId,
        status: { in: ['pending', 'failed'] },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  // Add item to sync queue
  async addToSyncQueue(data: {
    userId: string;
    operation: string;
    entity: string;
    entityId: string;
    data: any;
  }) {
    return this.prisma.syncQueue.create({
      data: {
        ...data,
        data: data.data,
        status: 'pending',
      },
    });
  }

  // Process sync queue
  async processSyncQueue(userId: string) {
    const pendingItems = await this.getPendingSyncItems(userId);
    const results = [];

    for (const item of pendingItems) {
      try {
        // Update status to syncing
        await this.prisma.syncQueue.update({
          where: { id: item.id },
          data: { status: 'syncing' },
        });

        // Process based on entity type
        let result;
        switch (item.entity) {
          case 'device':
            result = await this.syncDevice(item);
            break;
          case 'blob':
            result = await this.syncBlob(item);
            break;
          case 'securityLog':
            result = await this.syncSecurityLog(item);
            break;
          default:
            throw new Error(`Unknown entity type: ${item.entity}`);
        }

        // Mark as completed
        await this.prisma.syncQueue.update({
          where: { id: item.id },
          data: { status: 'completed' },
        });

        results.push({ id: item.id, success: true, result });
      } catch (error) {
        this.logger.error(`Sync failed for item ${item.id}`, error);
        
        // Update retry count and status
        await this.prisma.syncQueue.update({
          where: { id: item.id },
          data: {
            status: 'failed',
            retryCount: { increment: 1 },
            error: error.message,
          },
        });

        results.push({ id: item.id, success: false, error: error.message });
      }
    }

    return {
      processed: results.length,
      successful: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length,
      results,
    };
  }

  // Sync device data
  private async syncDevice(item: any) {
    const data = item.data as any;
    
    switch (item.operation) {
      case 'CREATE':
        return this.prisma.device.create({ data });
      case 'UPDATE':
        return this.prisma.device.update({
          where: { id: item.entityId },
          data,
        });
      case 'DELETE':
        return this.prisma.device.delete({
          where: { id: item.entityId },
        });
      default:
        throw new Error(`Unknown operation: ${item.operation}`);
    }
  }

  // Sync blob data
  private async syncBlob(item: any) {
    const data = item.data as any;
    
    switch (item.operation) {
      case 'CREATE':
      case 'UPDATE':
        return this.prisma.encryptedBlob.upsert({
          where: {
            userId_namespace_itemKey: {
              userId: data.userId,
              namespace: data.namespace,
              itemKey: data.itemKey,
            },
          },
          create: data,
          update: data,
        });
      case 'DELETE':
        return this.prisma.encryptedBlob.delete({
          where: { id: item.entityId },
        });
      default:
        throw new Error(`Unknown operation: ${item.operation}`);
    }
  }

  // Sync security log
  private async syncSecurityLog(item: any) {
    const data = item.data as any;
    
    if (item.operation === 'CREATE') {
      return this.prisma.securityLog.create({ data });
    }
    
    throw new Error(`Operation ${item.operation} not supported for security logs`);
  }

  // Get sync status for a user
  async getSyncStatus(userId: string) {
    const [pending, completed, failed] = await Promise.all([
      this.prisma.syncQueue.count({
        where: { userId, status: 'pending' },
      }),
      this.prisma.syncQueue.count({
        where: { userId, status: 'completed' },
      }),
      this.prisma.syncQueue.count({
        where: { userId, status: 'failed' },
      }),
    ]);

    const devices = await this.prisma.device.findMany({
      where: { userId },
      select: {
        id: true,
        name: true,
        syncStatus: true,
        lastSyncAt: true,
        isOnline: true,
      },
    });

    return {
      queue: { pending, completed, failed },
      devices,
      lastSync: await this.getLastSyncTime(userId),
    };
  }

  private async getLastSyncTime(userId: string) {
    const lastSync = await this.prisma.syncQueue.findFirst({
      where: { userId, status: 'completed' },
      orderBy: { updatedAt: 'desc' },
      select: { updatedAt: true },
    });
    
    return lastSync?.updatedAt || null;
  }

  // Clear completed sync items older than 7 days
  async cleanupSyncQueue() {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const deleted = await this.prisma.syncQueue.deleteMany({
      where: {
        status: 'completed',
        updatedAt: { lt: sevenDaysAgo },
      },
    });

    this.logger.log(`Cleaned up ${deleted.count} completed sync items`);
    return deleted.count;
  }
}
