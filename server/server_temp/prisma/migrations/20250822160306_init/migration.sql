-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "password_verifier_v2" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "EncryptedBlob" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "namespace" TEXT NOT NULL,
    "itemKey" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "ciphertext" TEXT NOT NULL,
    "nonce" TEXT NOT NULL,
    "mac" TEXT NOT NULL,
    "aad" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "EncryptedBlob_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "EncryptedBlob_userId_namespace_itemKey_key" ON "EncryptedBlob"("userId", "namespace", "itemKey");
