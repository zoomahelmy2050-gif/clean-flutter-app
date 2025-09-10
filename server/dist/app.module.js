var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { AuthModule } from './auth/auth.module.js';
import { BlobsModule } from './blobs/blobs.module.js';
import { MigrationsModule } from './migrations/migrations.module.js';
import { SyncModule } from './sync/sync.module.js';
import { ReportsModule } from './reports/reports.module.js';
import { NotificationsModule } from './notifications/notifications.module.js';
let AppModule = class AppModule {
};
AppModule = __decorate([
    Module({
        imports: [
            ConfigModule.forRoot({ isGlobal: true }),
            PrismaModule,
            AuthModule,
            BlobsModule,
            MigrationsModule,
            SyncModule,
            ReportsModule,
            NotificationsModule,
        ],
        controllers: [AppController],
        providers: [],
    })
], AppModule);
export { AppModule };
//# sourceMappingURL=app.module.js.map