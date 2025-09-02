import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { JwtService } from '@nestjs/jwt';
import { createHmac, pbkdf2Sync } from 'crypto';

function parseV2Record(record: string) {
  if (!record.startsWith('v2:')) throw new Error('Unsupported record');
  const parts = record.split(':');
  if (parts.length !== 4) throw new Error('Malformed record');
  const saltB64 = parts[1];
  const itersStr = parts[2];
  const verifierB64 = parts[3];
  const salt = Buffer.from(saltB64, 'base64');
  const iterations = Number.parseInt(itersStr, 10);
  const verifier = Buffer.from(verifierB64, 'base64');
  if (!Number.isFinite(iterations) || iterations < 1) throw new Error('Bad iterations');
  return { salt, iterations, verifier };
}

function computeVerifier(password: string, salt: Buffer, iterations: number) {
  const key = pbkdf2Sync(Buffer.from(password, 'utf8'), salt, iterations, 32, 'sha256');
  const mac = createHmac('sha256', salt).update(key).digest();
  return mac;
}

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService, private jwt: JwtService) {}

  async register(email: string, passwordRecordV2: string) {
    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) throw new ConflictException('Email already exists');
    const created = await this.prisma.user.create({
      data: {
        email,
        password_verifier_v2: passwordRecordV2,
      },
    });
    return { id: created.id, email: created.email };
  }

  async login(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) throw new UnauthorizedException('Invalid credentials');
    const rec = user.password_verifier_v2;
    const { salt, iterations, verifier } = parseV2Record(rec);
    const got = computeVerifier(password, salt, iterations);
    if (!timingSafeEqual(verifier, got)) throw new UnauthorizedException('Invalid credentials');
    const payload = { sub: user.id, email: user.email };
    const accessToken = await this.jwt.signAsync(payload);
    return { accessToken };
  }

  async rotateVerifier(userId: string, newRecord: string) {
    await this.prisma.user.update({ where: { id: userId }, data: { password_verifier_v2: newRecord } });
    return { ok: true };
  }
}

function timingSafeEqual(a: Buffer, b: Buffer) {
  if (a.length !== b.length) return false;
  let out = 0;
  for (let i = 0; i < a.length; i++) {
    out |= a[i] ^ b[i];
  }
  return out === 0;
}
