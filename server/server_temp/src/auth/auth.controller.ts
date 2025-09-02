import { Body, Controller, HttpCode, HttpStatus, Post, Req, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service.js';
import { Request } from 'express';
import { JwtGuard } from './jwt.guard.js';

@Controller('auth')
export class AuthController {
  constructor(private auth: AuthService) {}

  @Post('register')
  async register(@Body() body: any) {
    const email: string = String(body?.email ?? '').toLowerCase();
    const record: string = String(body?.passwordRecordV2 ?? '');
    if (!email || !record.startsWith('v2:')) {
      return { error: 'Invalid payload' };
    }
    const out = await this.auth.register(email, record);
    return out;
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() body: any) {
    const email: string = String(body?.email ?? '').toLowerCase();
    const password: string = String(body?.password ?? '');
    const out = await this.auth.login(email, password);
    return out;
  }

  @Post('rotate-verifier')
  @UseGuards(JwtGuard)
  async rotate(@Req() req: Request, @Body() body: any) {
    const userId = (req as any).user?.sub as string;
    const record: string = String(body?.passwordRecordV2 ?? '');
    await this.auth.rotateVerifier(userId, record);
    return { ok: true };
  }
}
