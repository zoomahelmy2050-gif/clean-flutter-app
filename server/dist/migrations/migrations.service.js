var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var MigrationsService_1;
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { exec } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(exec);
let MigrationsService = MigrationsService_1 = class MigrationsService {
    prisma;
    logger = new Logger(MigrationsService_1.name);
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getMigrationStatus() {
        try {
            // Get all migrations from database
            const migrations = await this.prisma.migration.findMany({
                orderBy: { createdAt: 'desc' },
            });
            // Check pending migrations
            const { stdout } = await execAsync('npx prisma migrate status', {
                cwd: process.cwd(),
            });
            return {
                migrations,
                prismaStatus: stdout,
                databaseConnected: true,
            };
        }
        catch (error) {
            this.logger.error('Failed to get migration status', error);
            return {
                migrations: [],
                prismaStatus: null,
                databaseConnected: false,
                error: error.message,
            };
        }
    }
    async applyMigrations() {
        try {
            this.logger.log('Applying database migrations...');
            // Run Prisma migrations
            const { stdout, stderr } = await execAsync('npx prisma migrate deploy', {
                cwd: process.cwd(),
            });
            // Record migration in database
            await this.prisma.migration.create({
                data: {
                    version: new Date().toISOString(),
                    name: 'Production Migration',
                    status: 'applied',
                    appliedAt: new Date(),
                },
            });
            return {
                success: true,
                output: stdout,
                error: stderr,
            };
        }
        catch (error) {
            this.logger.error('Failed to apply migrations', error);
            // Record failed migration
            await this.prisma.migration.create({
                data: {
                    version: new Date().toISOString(),
                    name: 'Failed Migration',
                    status: 'failed',
                    error: error.message,
                },
            });
            throw error;
        }
    }
    async rollbackMigration(version) {
        try {
            this.logger.log(`Rolling back migration ${version}...`);
            // Update migration status
            await this.prisma.migration.update({
                where: { version },
                data: {
                    status: 'rolled_back',
                    rolledBackAt: new Date(),
                },
            });
            return {
                success: true,
                message: `Migration ${version} rolled back`,
            };
        }
        catch (error) {
            this.logger.error('Failed to rollback migration', error);
            throw error;
        }
    }
    async resetDatabase() {
        try {
            this.logger.warn('Resetting database...');
            // Only allow in development
            if (process.env.NODE_ENV === 'production') {
                throw new Error('Database reset not allowed in production');
            }
            const { stdout } = await execAsync('npx prisma migrate reset --force', {
                cwd: process.cwd(),
            });
            return {
                success: true,
                output: stdout,
            };
        }
        catch (error) {
            this.logger.error('Failed to reset database', error);
            throw error;
        }
    }
};
MigrationsService = MigrationsService_1 = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], MigrationsService);
export { MigrationsService };
//# sourceMappingURL=migrations.service.js.map