var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { BlobsService } from './blobs.service.js';
import { BlobsController } from './blobs.controller.js';
import { JwtGuard } from '../auth/jwt.guard.js';
let BlobsModule = class BlobsModule {
};
BlobsModule = __decorate([
    Module({
        imports: [
            JwtModule.registerAsync({
                imports: [ConfigModule],
                useFactory: async (config) => ({
                    secret: config.get('JWT_SECRET') ?? 'dev-secret-change-me',
                    signOptions: { expiresIn: '2h' },
                }),
                inject: [ConfigService],
            }),
        ],
        providers: [BlobsService, JwtGuard],
        controllers: [BlobsController],
        exports: [BlobsService],
    })
], BlobsModule);
export { BlobsModule };
//# sourceMappingURL=blobs.module.js.map