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
import { Body, Controller, Get, Param, Put, Req, UseGuards } from '@nestjs/common';
import { BlobsService } from './blobs.service.js';
import { JwtGuard } from '../auth/jwt.guard.js';
const DEFAULT_NAMESPACE = 'default';
let BlobsController = class BlobsController {
    blobs;
    constructor(blobs) {
        this.blobs = blobs;
    }
    async list(req) {
        const userId = req.user?.sub;
        return this.blobs.list(userId);
    }
    async get(req, key) {
        const userId = req.user?.sub;
        return this.blobs.get(userId, DEFAULT_NAMESPACE, key);
    }
    async put(req, key, body) {
        const userId = req.user?.sub;
        const blob = {
            ciphertext: String(body.ciphertext),
            nonce: String(body.nonce),
            mac: String(body.mac),
            aad: body.aad != null ? String(body.aad) : null,
            version: String(body.version),
        };
        return this.blobs.put(userId, DEFAULT_NAMESPACE, key, blob);
    }
};
__decorate([
    Get('list'),
    __param(0, Req()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BlobsController.prototype, "list", null);
__decorate([
    Get(':key'),
    __param(0, Req()),
    __param(1, Param('key')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BlobsController.prototype, "get", null);
__decorate([
    Put(':key'),
    __param(0, Req()),
    __param(1, Param('key')),
    __param(2, Body()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BlobsController.prototype, "put", null);
BlobsController = __decorate([
    Controller('blobs'),
    UseGuards(JwtGuard),
    __metadata("design:paramtypes", [BlobsService])
], BlobsController);
export { BlobsController };
//# sourceMappingURL=blobs.controller.js.map