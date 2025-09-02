var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
let BlobsService = class BlobsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async list(userId) {
        const blobs = await this.prisma.encryptedBlob.findMany({
            where: { userId },
            select: { namespace: true, itemKey: true, version: true, aad: true },
        });
        return { blobs };
    }
    async get(userId, namespace, itemKey) {
        const blob = await this.prisma.encryptedBlob.findUnique({
            where: { userId_namespace_itemKey: { userId, namespace, itemKey } },
        });
        if (!blob) {
            throw new NotFoundException('Blob not found');
        }
        return blob;
    }
    async put(userId, namespace, itemKey, data) {
        const { version, ...rest } = data;
        const blob = await this.prisma.encryptedBlob.upsert({
            where: { userId_namespace_itemKey: { userId, namespace, itemKey } },
            update: { ...rest, version: parseInt(version, 10) },
            create: { userId, namespace, itemKey, ...rest, version: parseInt(version, 10) },
        });
        return { key: blob.itemKey, version: blob.version };
    }
};
BlobsService = __decorate([
    Injectable(),
    __metadata("design:paramtypes", [PrismaService])
], BlobsService);
export { BlobsService };
//# sourceMappingURL=blobs.service.js.map