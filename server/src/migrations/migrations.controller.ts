import { Controller, Get, Post, UseGuards, HttpException, HttpStatus } from '@nestjs/common';
import { MigrationsService } from './migrations.service.js';
import { JwtGuard } from '../auth/jwt.guard.js';

@Controller('migrations')
export class MigrationsController {
  constructor(private migrationsService: MigrationsService) {}

  @Get('status')
  @UseGuards(JwtGuard)
  async getStatus() {
    return this.migrationsService.getMigrationStatus();
  }

  @Post('apply')
  @UseGuards(JwtGuard)
  async applyMigrations() {
    try {
      return await this.migrationsService.applyMigrations();
    } catch (error: any) {
      throw new HttpException(
        error.message,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post('reset')
  @UseGuards(JwtGuard)
  async resetDatabase() {
    try {
      return await this.migrationsService.resetDatabase();
    } catch (error: any) {
      throw new HttpException(
        error.message,
        HttpStatus.FORBIDDEN,
      );
    }
  }
}
