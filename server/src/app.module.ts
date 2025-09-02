import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { AuthModule } from './auth/auth.module.js';
import { BlobsModule } from './blobs/blobs.module.js';
import { MigrationsModule } from './migrations/migrations.module.js';
import { SyncModule } from './sync/sync.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    BlobsModule,
    MigrationsModule,
    SyncModule,
  ],
  controllers: [AppController],
  providers: [],
})
export class AppModule {}
