import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

@Injectable()
export class MigrationsService {
  private readonly logger = new Logger(MigrationsService.name);

  constructor(private prisma: PrismaService) {}

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
    } catch (error) {
      this.logger.error('Failed to get migration status', error as Error);
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
    } catch (error) {
      this.logger.error('Failed to apply migrations', error);
      
      // Record failed migration
      await this.prisma.migration.create({
        data: {
          version: new Date().toISOString(),
          name: 'Failed Migration',
          status: 'failed',
          error: (error as Error).message,
        },
      });

      throw error;
    }
  }

  async rollbackMigration(version: string) {
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
    } catch (error) {
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
    } catch (error) {
      this.logger.error('Failed to reset database', error);
      throw error;
    }
  }
}
