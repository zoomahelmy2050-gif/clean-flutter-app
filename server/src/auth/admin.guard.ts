import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { Request } from 'express';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const user = (request as any)?.user;
    const userId = (user as any)?.sub as string | undefined;

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
}
