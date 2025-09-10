import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

@Injectable()
export class JwtGuard implements CanActivate {
  constructor(private jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = this.extractToken(request);
    if (!token) {
      throw new UnauthorizedException('No token provided');
    }
    try {
      const payload = await this.jwtService.verifyAsync(token);
      request['user'] = payload;
    } catch (e) {
      throw new UnauthorizedException('Invalid token');
    }
    return true;
  }

  private extractToken(request: Request): string | undefined {
    // 1) Authorization: Bearer <token>
    const [type, headerToken] = request.headers.authorization?.split(' ') ?? [];
    if (type === 'Bearer' && headerToken) return headerToken;

    // 2) Query string: ?access_token=... or ?token=...
    const anyReq = request as any;
    const q = anyReq?.query ?? {};
    const queryToken = q['access_token'] ?? q['token'];
    if (typeof queryToken === 'string' && queryToken.length > 0) return queryToken;

    return undefined;
  }
}
