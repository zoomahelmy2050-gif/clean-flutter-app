# Complete GitHub to Railway Deployment Guide

## 📋 **PART 1: GitHub Repository Setup**

### Step 1: Prepare Your Repository
1. **Open Terminal/Command Prompt** in your project folder:
   ```bash
   cd c:\Users\Hazem\clean_flutter
   ```

2. **Initialize Git** (if not already done):
   ```bash
   git init
   git add .
   git commit -m "Initial commit - Flutter app with NestJS server"
   ```

3. **Create GitHub Repository**:
   - Go to [github.com](https://github.com)
   - Click **"New repository"** (green button)
   - Repository name: `clean-flutter-app` (or your preferred name)
   - Set to **Public** or **Private**
   - **DO NOT** initialize with README (you already have files)
   - Click **"Create repository"**

4. **Connect Local to GitHub**:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/clean-flutter-app.git
   git branch -M main
   git push -u origin main
   ```

### Step 2: Verify GitHub Upload
1. **Check GitHub**: Refresh your repository page
2. **Verify Structure**: You should see:
   ```
   ├── lib/          (Flutter app)
   ├── server/       (NestJS backend)
   ├── android/
   ├── ios/
   └── pubspec.yaml
   ```

---

## 🚂 **PART 2: Railway Account & Project Setup**

### Step 3: Create Railway Account
1. **Go to Railway**: [railway.app](https://railway.app)
2. **Sign Up Options**:
   - Click **"Login"** → **"Sign up"**
   - Choose **"Continue with GitHub"** (recommended)
   - Authorize Railway to access your GitHub

### Step 4: Create New Project
1. **Dashboard**: You'll see Railway dashboard
2. **New Project**: Click **"New Project"** button
3. **Deploy Options**: Select **"Deploy from GitHub repo"**
4. **Repository Selection**:
   - Find your repository: `clean-flutter-app`
   - Click **"Deploy"**

### Step 5: Configure Root Directory
1. **Deployment Failed?** That's expected - we need to configure
2. **Project Settings**:
   - Click on your project name
   - Go to **"Settings"** tab
   - Find **"Root Directory"** section
   - Set to: `/server`
   - Click **"Update"**

---

## 🗄️ **PART 3: Database Setup**

### Step 6: Add PostgreSQL Database
1. **In Railway Project**: Click **"New Service"**
2. **Database Selection**: Click **"Database"**
3. **PostgreSQL**: Select **"PostgreSQL"**
4. **Auto-Configuration**: Railway creates database automatically
5. **Database URL**: Railway generates `DATABASE_URL` environment variable

### Step 7: Verify Database
1. **Services Tab**: You should see:
   - Your app service (from GitHub)
   - PostgreSQL service
2. **Database Info**: Click PostgreSQL service to see connection details

---

## ⚙️ **PART 4: Environment Variables**

### Step 8: Generate JWT Secret
1. **Open Terminal** in your server folder:
   ```bash
   cd c:\Users\Hazem\clean_flutter\server
   node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(64).toString('hex'))"
   ```
2. **Copy the output** (long random string)

### Step 9: Set Environment Variables
1. **Railway Dashboard**: Click your app service (not database)
2. **Variables Tab**: Click **"Variables"**
3. **Add Variables** one by one:

   **Variable 1:**
   - Name: `NODE_ENV`
   - Value: `production`

   **Variable 2:**
   - Name: `PORT`
   - Value: `3000`

   **Variable 3:**
   - Name: `JWT_SECRET`
   - Value: [Paste the generated secret from Step 8]

   **Variable 4:**
   - Name: `CORS_ORIGINS`
   - Value: `http://localhost:3000,https://localhost:3000`

4. **Save**: Click **"Add"** for each variable

---

## 🚀 **PART 5: Deploy & Monitor**

### Step 10: Trigger Deployment
1. **Deployments Tab**: Click **"Deployments"**
2. **Redeploy**: Click **"Deploy Latest"** or push new commit to GitHub
3. **Build Logs**: Watch the build process in real-time
4. **Expected Build Steps**:
   ```
   ✅ Cloning repository
   ✅ Installing dependencies (npm ci)
   ✅ Building TypeScript (npm run build)
   ✅ Generating Prisma client
   ✅ Starting server (npm start)
   ```

### Step 11: Get Your Railway URL
1. **Settings Tab**: Click **"Settings"**
2. **Domains Section**: Find your Railway URL
   - Format: `https://your-project-name-production-xxxx.up.railway.app`
3. **Copy URL**: Save this for Flutter app configuration

### Step 12: Test Deployment
1. **Health Check**: Open browser and go to:
   ```
   https://your-railway-url.up.railway.app/health
   ```
2. **Expected Response**:
   ```json
   {
     "status": "ok",
     "timestamp": "2025-01-02T10:30:00.000Z",
     "uptime": 123.45,
     "environment": "production"
   }
   ```

---

## 📱 **PART 6: Connect Flutter App**

### Step 13: Update Flutter Configuration
1. **Open File**: `lib/core/config/api_config.dart`
2. **Replace URL**: Change the defaultValue:
   ```dart
   static const String baseUrl = String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://your-actual-railway-url.up.railway.app',
   );
   ```
3. **Save File**

### Step 14: Test Flutter Connection
1. **Run Flutter App**:
   ```bash
   cd c:\Users\Hazem\clean_flutter
   flutter run
   ```
2. **Check Logs**: Look for successful API calls in debug console

---

## ✅ **PART 7: Verification Checklist**

### Step 15: Complete Testing
- [ ] Railway URL responds to `/health`
- [ ] Database connection works
- [ ] Environment variables are set
- [ ] Flutter app connects to Railway server
- [ ] No CORS errors in browser console

### Step 16: Monitor Deployment
1. **Railway Logs**: Check **"Deployments"** → **"View Logs"**
2. **Database Metrics**: Monitor PostgreSQL service
3. **Error Tracking**: Watch for any runtime errors

---

## 🔧 **Troubleshooting Common Issues**

### Build Failures:
- **Missing Dependencies**: Check `package.json` in `/server`
- **TypeScript Errors**: Review build logs for compilation issues
- **Prisma Issues**: Ensure `DATABASE_URL` is set

### Runtime Errors:
- **Port Issues**: Verify `PORT=3000` in environment variables
- **Database Connection**: Check PostgreSQL service is running
- **CORS Errors**: Update `CORS_ORIGINS` with your Flutter app domain

### Flutter Connection Issues:
- **Wrong URL**: Verify Railway URL in `api_config.dart`
- **Network Errors**: Check if Railway service is running
- **SSL Issues**: Ensure using `https://` not `http://`

---

## 🎉 **Success!**

Your Flutter app is now deployed to Railway with:
- ✅ NestJS backend server
- ✅ PostgreSQL database
- ✅ Automatic deployments from GitHub
- ✅ Production environment variables
- ✅ HTTPS endpoint

**Railway URL**: `https://your-project-name.up.railway.app`
