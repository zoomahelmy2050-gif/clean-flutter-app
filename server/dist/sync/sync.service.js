var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var SyncService_1;
var _a;
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
let SyncService = SyncService_1 = class SyncService {
    prisma;
    logger = new Logger(SyncService_1.name);
    constructor(prisma) {
        this.prisma = prisma;
    }
    // Get pending sync items for a user
    async getPendingSyncItems(userId) {
        return this.prisma.syncQueue.findMany({
            where: {
                userId,
                status: { in: ['pending', 'failed'] },
            },
            orderBy: { createdAt: 'asc' },
        });
    }
    // Add item to sync queue
    async addToSyncQueue(data) {
        return this.prisma.syncQueue.create({
            data: {
                ...data,
                data: data.data,
                status: 'pending',
            },
        });
    }
    // Process sync queue
    async processSyncQueue(userId) {
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
            }
            catch (error) {
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
    async syncDevice(item) {
        const data = item.data;
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
    async syncBlob(item) {
        const data = item.data;
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
    async syncSecurityLog(item) {
        const data = item.data;
        if (item.operation === 'CREATE') {
            return this.prisma.securityLog.create({ data });
        }
        throw new Error(`Operation ${item.operation} not supported for security logs`);
    }
    // Get sync status for a user
    async getSyncStatus(userId) {
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
    async getLastSyncTime(userId) {
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
};
SyncService = SyncService_1 = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [typeof (_a = typeof PrismaService !== "undefined" && PrismaService) === "function" ? _a : Object])
], SyncService);
export { SyncService };
//# sourceMappingURL=sync.service.js.map