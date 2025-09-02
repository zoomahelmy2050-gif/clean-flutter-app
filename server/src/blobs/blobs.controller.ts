import { Body, Controller, Get, Param, Put, Req, UseGuards } from '@nestjs/common';
import { BlobsService } from './blobs.service.js';
import { Request } from 'express';
import { JwtGuard } from '../auth/jwt.guard.js';

const DEFAULT_NAMESPACE = 'default';

@Controller('blobs')
@UseGuards(JwtGuard)
export class BlobsController {
  constructor(private blobs: BlobsService) {}

  @Get('list')
  async list(@Req() req: Request) {
    const userId = (req as any).user?.sub as string;
    return this.blobs.list(userId);
  }

  @Get(':key')
  async get(@Req() req: Request, @Param('key') key: string) {
    const userId = (req as any).user?.sub as string;
    return this.blobs.get(userId, DEFAULT_NAMESPACE, key);
  }

  @Put(':key')
  async put(@Req() req: Request, @Param('key') key: string, @Body() body: any) {
    const userId = (req as any).user?.sub as string;
    const blob = {
      ciphertext: String(body.ciphertext),
      nonce: String(body.nonce),
      mac: String(body.mac),
      aad: body.aad != null ? String(body.aad) : null,
      version: String(body.version),
    };
    return this.blobs.put(userId, DEFAULT_NAMESPACE, key, blob);
  }
}
