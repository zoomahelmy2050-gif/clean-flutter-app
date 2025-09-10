var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
let AdminGuard = class AdminGuard {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async canActivate(context) {
        const request = context.switchToHttp().getRequest();
        const user = request?.user;
        const userId = user?.sub;
        if (!userId) {
            throw new ForbiddenException('Missing authenticated user');
        }
        const dbUser = await this.prisma.user.findUnique({
            where: { id: userId },
            select: { role: true, isSuperAdmin: true },
        });
        if (!dbUser) {
            throw new ForbiddenException('User not found');
        }
        if (dbUser.isSuperAdmin || dbUser.role === 'ADMIN' || dbUser.role === 'SUPER_ADMIN') {
            return true;
        }
        throw new ForbiddenException('Admin privileges required');
    }
};
AdminGuard = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], AdminGuard);
export { AdminGuard };
//# sourceMappingURL=admin.guard.js.map