var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { JwtService } from '@nestjs/jwt';
import { createHmac, pbkdf2Sync } from 'crypto';
function parseV2Record(record) {
    if (!record.startsWith('v2:'))
        throw new Error('Unsupported record');
    const parts = record.split(':');
    if (parts.length !== 4)
        throw new Error('Malformed record');
    const saltB64 = parts[1];
    const itersStr = parts[2];
    const verifierB64 = parts[3];
    const salt = Buffer.from(saltB64, 'base64');
    const iterations = Number.parseInt(itersStr, 10);
    const verifier = Buffer.from(verifierB64, 'base64');
    if (!Number.isFinite(iterations) || iterations < 1)
        throw new Error('Bad iterations');
    return { salt, iterations, verifier };
}
function computeVerifier(password, salt, iterations) {
    const key = pbkdf2Sync(Buffer.from(password, 'utf8'), salt, iterations, 32, 'sha256');
    const mac = createHmac('sha256', salt).update(key).digest();
    return mac;
}
let AuthService = class AuthService {
    prisma;
    jwt;
    constructor(prisma, jwt) {
        this.prisma = prisma;
        this.jwt = jwt;
    }
    async register(email, passwordRecordV2) {
        const exists = await this.prisma.user.findUnique({ where: { email } });
        if (exists)
            throw new ConflictException('Email already exists');
        const created = await this.prisma.user.create({
            data: {
                email,
                password_verifier_v2: passwordRecordV2,
            },
        });
        return { id: created.id, email: created.email };
    }
    async login(email, password) {
        const user = await this.prisma.user.findUnique({ where: { email } });
        if (!user)
            throw new UnauthorizedException('Invalid credentials');
        const rec = user.password_verifier_v2;
        const { salt, iterations, verifier } = parseV2Record(rec);
        const got = computeVerifier(password, salt, iterations);
        if (!timingSafeEqual(verifier, got))
            throw new UnauthorizedException('Invalid credentials');
        const payload = { sub: user.id, email: user.email };
        const accessToken = await this.jwt.signAsync(payload);
        return { accessToken };
    }
    async rotateVerifier(userId, newRecord) {
        await this.prisma.user.update({ where: { id: userId }, data: { password_verifier_v2: newRecord } });
        return { ok: true };
    }
};
AuthService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService, JwtService])
], AuthService);
export { AuthService };
function timingSafeEqual(a, b) {
    if (a.length !== b.length)
        return false;
    let out = 0;
    for (let i = 0; i < a.length; i++) {
        out |= a[i] ^ b[i];
    }
    return out === 0;
}
//# sourceMappingURL=auth.service.js.map