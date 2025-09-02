# Render Deployment Guide

## Prerequisites
1. Create a [Render](https://render.com) account
2. Connect your GitHub repository to Render

## Step 1: Create PostgreSQL Database
1. Go to Render Dashboard → New → PostgreSQL
2. Name: `e2ee-postgres`
3. Database Name: `e2ee_production`
4. User: `e2ee_user`
5. Plan: Starter (Free)
6. Click "Create Database"
7. **Save the connection string** - you'll need it for the web service

## Step 2: Deploy Web Service
1. Go to Render Dashboard → New → Web Service
2. Connect your repository
3. Configure:
   - **Name**: `e2ee-server`
   - **Environment**: `Node`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm start`
   - **Plan**: Starter (Free)

## Step 3: Environment Variables
Add these environment variables in Render:

```
NODE_ENV=production
PORT=10000
DATABASE_URL=<your-postgresql-connection-string>
JWT_SECRET=<generate-secure-random-string>
```

### Generate JWT Secret
Run this command to generate a secure JWT secret:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## Step 4: Optional Email Configuration
If you want email notifications, add:
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=your-email@gmail.com
SMTP_FROM_NAME=Security Center
```

## Step 5: Deploy
1. Click "Create Web Service"
2. Render will automatically build and deploy
3. Your API will be available at: `https://your-service-name.onrender.com`

## Step 6: Update Flutter App
Update your Flutter app's API base URL to point to your Render service:
```dart
// In your Flutter app configuration
const String API_BASE_URL = 'https://your-service-name.onrender.com';
```

## Troubleshooting
- Check build logs in Render dashboard
- Ensure all environment variables are set
- Database migrations run automatically on deployment
- Free tier services sleep after 15 minutes of inactivity

## Health Check
Test your deployment:
```
GET https://your-service-name.onrender.com/health
```

Should return: `{"status": "ok", "timestamp": "..."}`
