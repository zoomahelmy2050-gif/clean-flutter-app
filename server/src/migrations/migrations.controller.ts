import { Controller, Get, Post, UseGuards, HttpException, HttpStatus } from '@nestjs/common';
import { MigrationsService } from './migrations.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('migrations')
export class MigrationsController {
  constructor(private migrationsService: MigrationsService) {}

  @Get('status')
  @UseGuards(JwtAuthGuard)
  async getStatus() {
    return this.migrationsService.getMigrationStatus();
  }

  @Post('apply')
  @UseGuards(JwtAuthGuard)
  async applyMigrations() {
    try {
      return await this.migrationsService.applyMigrations();
    } catch (error) {
      throw new HttpException(
        error.message,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post('reset')
  @UseGuards(JwtAuthGuard)
  async resetDatabase() {
    try {
      return await this.migrationsService.resetDatabase();
    } catch (error) {
      throw new HttpException(
        error.message,
        HttpStatus.FORBIDDEN,
      );
    }
  }
}
