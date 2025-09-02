import { Module } from '@nestjs/common';
import { MigrationsController } from './migrations.controller.js';
import { MigrationsService } from './migrations.service.js';
import { PrismaModule } from '../prisma/prisma.module.js';

@Module({
  imports: [PrismaModule],
  controllers: [MigrationsController],
  providers: [MigrationsService],
  exports: [MigrationsService],
})
export class MigrationsModule {}
