var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
import { Body, Controller, HttpCode, HttpStatus, Post, Req, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service.js';
import { JwtGuard } from './jwt.guard.js';
let AuthController = class AuthController {
    auth;
    constructor(auth) {
        this.auth = auth;
    }
    async register(body) {
        const email = String(body?.email ?? '').toLowerCase();
        const record = String(body?.passwordRecordV2 ?? '');
        if (!email || !record.startsWith('v2:')) {
            return { error: 'Invalid payload' };
        }
        const out = await this.auth.register(email, record);
        return out;
    }
    async login(body) {
        const email = String(body?.email ?? '').toLowerCase();
        const password = String(body?.password ?? '');
        const out = await this.auth.login(email, password);
        return out;
    }
    async rotate(req, body) {
        const userId = req.user?.sub;
        const record = String(body?.passwordRecordV2 ?? '');
        await this.auth.rotateVerifier(userId, record);
        return { ok: true };
    }
};
__decorate([
    Post('register'),
    __param(0, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "register", null);
__decorate([
    Post('login'),
    HttpCode(HttpStatus.OK),
    __param(0, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "login", null);
__decorate([
    Post('rotate-verifier'),
    UseGuards(JwtGuard),
    __param(0, Req()),
    __param(1, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "rotate", null);
AuthController = __decorate([
    Controller('auth'),
    __metadata("design:paramtypes", [AuthService])
], AuthController);
export { AuthController };
//# sourceMappingURL=auth.controller.js.map