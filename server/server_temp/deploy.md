# Cloud Deployment Guide

## Environment Variables for Railway:

Set these in Railway dashboard:

```
DATABASE_URL=file:./dev.db
JWT_SECRET=your-super-secret-jwt-key-here-make-it-long-and-random
PORT=3000
NODE_ENV=production
```

## Deployment Steps:

1. Create Railway account at railway.app
2. Connect your GitHub repository
3. Deploy from GitHub
4. Set environment variables
5. Update Flutter app with new URL
