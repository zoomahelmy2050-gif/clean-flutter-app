# Final Railway Deployment Steps

## 🎯 **IMMEDIATE ACTIONS REQUIRED**

### 1. **Railway Account & Project Setup**
```
1. Go to: https://railway.app
2. Sign up/Login with GitHub
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your repository
5. Set Root Directory: /server
```

### 2. **Add PostgreSQL Database**
```
1. In Railway project dashboard
2. Click "New Service" → "Database" → "PostgreSQL"
3. Railway auto-generates DATABASE_URL
```

### 3. **Environment Variables**
Add these in Railway Settings → Variables:
```
NODE_ENV=production
PORT=3000
JWT_SECRET=[Generate with command below]
CORS_ORIGINS=http://localhost:3000,https://your-flutter-domain.com
```

### 4. **Generate JWT Secret**
Run in terminal:
```bash
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(64).toString('hex'))"
```

### 5. **Deploy & Test**
```
1. Push code to GitHub
2. Railway auto-deploys
3. Get your URL: https://your-project-name.up.railway.app
4. Test with: curl https://your-project-name.up.railway.app/health
```

### 6. **Update Flutter App**
Replace in `lib/core/config/api_config.dart`:
```dart
defaultValue: 'https://your-actual-railway-url.up.railway.app',
```

## 🧪 **Testing Commands**

### Test Health Endpoint:
```bash
curl https://your-project-name.up.railway.app/health
```

### Test API:
```bash
curl https://your-project-name.up.railway.app/api
```

### PowerShell Test Script:
```powershell
.\test-deployment.ps1 -RailwayUrl "https://your-project-name.up.railway.app"
```

## ✅ **Success Indicators**
- Railway build completes without errors
- Health endpoint returns JSON response
- Database migrations run successfully
- Flutter app connects to Railway server

## 🔧 **Troubleshooting**
- Check Railway logs for build errors
- Verify all environment variables are set
- Ensure DATABASE_URL is populated
- Check CORS settings if Flutter connection fails

**Your server is now ready for Railway deployment!**
