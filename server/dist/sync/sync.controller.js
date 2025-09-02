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
import { Controller, Get, Post, Body, UseGuards, Req, Request } from '@nestjs/common';
import { SyncService } from './sync.service.js';
import { JwtGuard } from '../auth/jwt.guard.js';
let SyncController = class SyncController {
    syncService;
    constructor(syncService) {
        this.syncService = syncService;
    }
    async getSyncStatus(req) {
        return this.syncService.getSyncStatus(req.user.id);
    }
    async getPendingItems(req) {
        return this.syncService.getPendingSyncItems(req.user.id);
    }
    async addToQueue(req, data) {
        return this.syncService.addToSyncQueue({
            userId: req.user.id,
            ...data,
        });
    }
    async getQueue(req) {
        return this.syncService.processSyncQueue(req.user.id);
    }
    async cleanup() {
        return this.syncService.cleanupSyncQueue();
    }
};
__decorate([
    Get('status'),
    UseGuards(JwtGuard),
    __param(0, Req()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SyncController.prototype, "getSyncStatus", null);
__decorate([
    Get('pending'),
    UseGuards(JwtGuard),
    __param(0, Request()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SyncController.prototype, "getPendingItems", null);
__decorate([
    Post('queue'),
    UseGuards(JwtGuard),
    __param(0, Request()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], SyncController.prototype, "addToQueue", null);
__decorate([
    Post('process'),
    UseGuards(JwtGuard),
    __param(0, Request()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SyncController.prototype, "getQueue", null);
__decorate([
    Post('cleanup'),
    UseGuards(JwtGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], SyncController.prototype, "cleanup", null);
SyncController = __decorate([
    Controller('sync'),
    __metadata("design:paramtypes", [SyncService])
], SyncController);
export { SyncController };
//# sourceMappingURL=sync.controller.js.map