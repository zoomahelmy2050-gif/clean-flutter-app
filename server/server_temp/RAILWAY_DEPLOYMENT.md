# Railway Deployment Guide

## Step 1: Railway Account Setup
1. Go to [railway.app](https://railway.app) and create an account
2. Click "New Project" → "Deploy from GitHub repo"
3. Connect your GitHub account and select your repository
4. Choose the `server` folder as the root directory

## Step 2: Add PostgreSQL Database
1. In your Railway project dashboard, click "New Service"
2. Select "Database" → "PostgreSQL"
3. Railway will automatically create a PostgreSQL database
4. The DATABASE_URL will be automatically provided

## Step 3: Configure Environment Variables
In your Railway project settings, add these environment variables:

### Required Variables:
```
NODE_ENV=production
JWT_SECRET=your-super-secure-jwt-secret-key-here-min-32-chars
PORT=3000
```

### Database (Automatically provided by Railway):
```
DATABASE_URL=postgresql://username:password@hostname:port/database
```

### Optional CORS Configuration:
```
CORS_ORIGINS=https://your-flutter-app-domain.com,http://localhost:3000
```

### Optional Email Configuration:
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=your-email@gmail.com
SMTP_FROM_NAME=Security Center
```

## Step 4: Deploy
1. Push your code to GitHub
2. Railway will automatically detect changes and deploy
3. Your server will be available at: `https://your-project-name.up.railway.app`

## Step 5: Generate JWT Secret
Run this command to generate a secure JWT secret:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## Step 6: Test Deployment
1. Visit your Railway app URL
2. Check the logs in Railway dashboard for any errors
3. Test API endpoints using Postman or curl

## Troubleshooting
- Check Railway logs for deployment errors
- Ensure all environment variables are set
- Verify DATABASE_URL is correctly configured
- Check that Prisma migrations run successfully
