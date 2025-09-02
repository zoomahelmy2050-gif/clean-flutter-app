import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

type BlobData = {
  ciphertext: string;
  nonce: string;
  mac: string;
  aad: string | null;
  version: string;
};

@Injectable()
export class BlobsService {
  constructor(private prisma: PrismaService) {}

  async list(userId: string) {
    const blobs = await this.prisma.encryptedBlob.findMany({
      where: { userId },
      select: { namespace: true, itemKey: true, version: true, aad: true },
    });
    return { blobs };
  }

  async get(userId: string, namespace: string, itemKey: string) {
    const blob = await this.prisma.encryptedBlob.findUnique({
      where: { userId_namespace_itemKey: { userId, namespace, itemKey } },
    });
    if (!blob) {
      throw new NotFoundException('Blob not found');
    }
    return blob;
  }

  async put(userId: string, namespace: string, itemKey: string, data: BlobData) {
    const { version, ...rest } = data;
    const blob = await this.prisma.encryptedBlob.upsert({
      where: { userId_namespace_itemKey: { userId, namespace, itemKey } },
      update: { ...rest, version: parseInt(version, 10) },
      create: { userId, namespace, itemKey, ...rest, version: parseInt(version, 10) },
    });
    return { key: blob.itemKey, version: blob.version };
  }
}
