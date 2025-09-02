import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BlobsService } from './blobs.service.js';
import { BlobsController } from './blobs.controller.js';
import { JwtGuard } from '../auth/jwt.guard.js';

@Module({
  imports: [
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (config: ConfigService) => ({
        secret: config.get<string>('JWT_SECRET') ?? 'dev-secret-change-me',
        signOptions: { expiresIn: '2h' },
      }),
      inject: [ConfigService],
    }),
  ],
  providers: [BlobsService, JwtGuard],
  controllers: [BlobsController],
  exports: [BlobsService],
})
export class BlobsModule {}
