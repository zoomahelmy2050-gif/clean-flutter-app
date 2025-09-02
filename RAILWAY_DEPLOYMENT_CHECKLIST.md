# Railway Deployment Checklist

## ✅ Pre-Deployment Steps

### 1. Railway Account Setup
- [ ] Create account at [railway.app](https://railway.app)
- [ ] Connect GitHub account
- [ ] Create new project

### 2. Database Setup
- [ ] Add PostgreSQL service to your Railway project
- [ ] Note the DATABASE_URL (automatically provided)

### 3. Environment Variables Setup
Copy these variables to Railway project settings > Variables:

```
NODE_ENV=production
PORT=3000
JWT_SECRET=[Generate using: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"]
CORS_ORIGINS=http://localhost:3000,https://your-flutter-app-domain.com
```

### 4. Deploy Server
- [ ] Push code to GitHub
- [ ] Connect GitHub repo to Railway
- [ ] Set root directory to `/server`
- [ ] Deploy and wait for build completion

### 5. Update Flutter App
- [ ] Update `lib/core/config/api_config.dart` with your Railway URL
- [ ] Replace `your-project-name` with actual Railway project name
- [ ] Test API connection

## 🚀 Deployment Commands

### Generate JWT Secret:
```bash
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(64).toString('hex'))"
```

### Test API Endpoints:
```bash
curl https://your-project-name.up.railway.app/api/health
```

## 📋 Post-Deployment Verification

- [ ] Server starts without errors
- [ ] Database migrations run successfully
- [ ] API endpoints respond correctly
- [ ] Flutter app connects to Railway server
- [ ] Authentication works properly

## 🔧 Troubleshooting

### Common Issues:
1. **Build fails**: Check Railway logs for missing dependencies
2. **Database connection**: Verify DATABASE_URL is set
3. **CORS errors**: Update CORS_ORIGINS with your Flutter app domain
4. **Port issues**: Ensure PORT=3000 in environment variables

### Railway Logs:
Check deployment logs in Railway dashboard for detailed error messages.
