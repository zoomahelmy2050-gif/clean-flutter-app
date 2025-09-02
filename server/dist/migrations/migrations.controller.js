var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var _a;
import { Controller, Get, Post, UseGuards, HttpException, HttpStatus } from '@nestjs/common';
import { MigrationsService } from './migrations.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
let MigrationsController = class MigrationsController {
    migrationsService;
    constructor(migrationsService) {
        this.migrationsService = migrationsService;
    }
    async getStatus() {
        return this.migrationsService.getMigrationStatus();
    }
    async applyMigrations() {
        try {
            return await this.migrationsService.applyMigrations();
        }
        catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    async resetDatabase() {
        try {
            return await this.migrationsService.resetDatabase();
        }
        catch (error) {
            throw new HttpException(error.message, HttpStatus.FORBIDDEN);
        }
    }
};
__decorate([
    Get('status'),
    UseGuards(JwtAuthGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MigrationsController.prototype, "getStatus", null);
__decorate([
    Post('apply'),
    UseGuards(JwtAuthGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MigrationsController.prototype, "applyMigrations", null);
__decorate([
    Post('reset'),
    UseGuards(JwtAuthGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MigrationsController.prototype, "resetDatabase", null);
MigrationsController = __decorate([
    Controller('migrations'),
    __metadata("design:paramtypes", [typeof (_a = typeof MigrationsService !== "undefined" && MigrationsService) === "function" ? _a : Object])
], MigrationsController);
export { MigrationsController };
//# sourceMappingURL=migrations.controller.js.map