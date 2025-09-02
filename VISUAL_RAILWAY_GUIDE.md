# Visual Step-by-Step: GitHub to Railway Deployment

## 🔥 **QUICK START COMMANDS**

First, run these commands in your terminal:

```bash
# 1. Navigate to your project
cd c:\Users\Hazem\clean_flutter

# 2. Generate JWT Secret (copy the output)
cd server
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(64).toString('hex'))"

# 3. Initialize Git (if not done)
git init
git add .
git commit -m "Initial commit"
```

---

## 📸 **VISUAL WALKTHROUGH**

### **STEP 1: GitHub Repository**

**1.1 Create Repository on GitHub:**
- Go to [github.com](https://github.com)
- Click green **"New"** button (top right)
- Repository name: `clean-flutter-app`
- Select **Public** or **Private**
- **IMPORTANT**: Do NOT check "Add a README file"
- Click **"Create repository"**

**1.2 Connect Your Local Code:**
```bash
# Replace YOUR_USERNAME with your GitHub username
git remote add origin https://github.com/YOUR_USERNAME/clean-flutter-app.git
git branch -M main
git push -u origin main
```

**1.3 Verify Upload:**
- Refresh GitHub page
- You should see folders: `lib/`, `server/`, `android/`, `ios/`, etc.

---

### **STEP 2: Railway Account Setup**

**2.1 Create Railway Account:**
- Go to [railway.app](https://railway.app)
- Click **"Login"** → **"Sign up"**
- Choose **"Continue with GitHub"** (blue button)
- Authorize Railway access

**2.2 Railway Dashboard:**
- You'll see empty dashboard
- Click **"New Project"** (purple button)

---

### **STEP 3: Deploy from GitHub**

**3.1 Project Creation:**
- Click **"Deploy from GitHub repo"**
- Find your repository: `clean-flutter-app`
- Click **"Deploy"**

**3.2 Initial Deployment (Will Fail - Expected!):**
- Railway starts building
- Build will fail because it's trying to build Flutter, not server
- This is normal - we'll fix it next

---

### **STEP 4: Configure Server Directory**

**4.1 Fix Root Directory:**
- In Railway project, click your service name
- Go to **"Settings"** tab (gear icon)
- Scroll to **"Root Directory"**
- Change from `/` to `/server`
- Click **"Update"**

**4.2 Redeploy:**
- Go to **"Deployments"** tab
- Click **"Deploy Latest"** button
- Watch build logs - should work now

---

### **STEP 5: Add Database**

**5.1 Add PostgreSQL:**
- In project dashboard, click **"New Service"**
- Click **"Database"**
- Select **"PostgreSQL"**
- Railway creates database automatically

**5.2 Verify Services:**
- You should now see 2 services:
  - Your app (from GitHub)
  - PostgreSQL database

---

### **STEP 6: Environment Variables**

**6.1 Access Variables:**
- Click your **app service** (not database)
- Click **"Variables"** tab
- Click **"New Variable"**

**6.2 Add Required Variables:**

**Variable 1:**
- Name: `NODE_ENV`
- Value: `production`
- Click **"Add"**

**Variable 2:**
- Name: `PORT`
- Value: `3000`
- Click **"Add"**

**Variable 3:**
- Name: `JWT_SECRET`
- Value: [Paste the secret you generated earlier]
- Click **"Add"**

**Variable 4:**
- Name: `CORS_ORIGINS`
- Value: `http://localhost:3000,https://localhost:3000`
- Click **"Add"**

---

### **STEP 7: Get Your Railway URL**

**7.1 Find Your URL:**
- Go to **"Settings"** tab
- Scroll to **"Domains"** section
- Copy the Railway URL (looks like: `https://clean-flutter-app-production-xxxx.up.railway.app`)

**7.2 Test Your Deployment:**
- Open browser
- Go to: `https://your-railway-url.up.railway.app/health`
- Should see JSON response like:
```json
{
  "status": "ok",
  "timestamp": "2025-01-02T10:30:00.000Z",
  "uptime": 123.45,
  "environment": "production"
}
```

---

### **STEP 8: Connect Flutter App**

**8.1 Update Flutter Configuration:**
- Open: `lib/core/config/api_config.dart`
- Replace the URL:
```dart
defaultValue: 'https://your-actual-railway-url.up.railway.app',
```

**8.2 Test Flutter App:**
```bash
flutter run
```

---

## ✅ **SUCCESS CHECKLIST**

- [ ] GitHub repository created and code uploaded
- [ ] Railway account created with GitHub
- [ ] Project deployed from GitHub repo
- [ ] Root directory set to `/server`
- [ ] PostgreSQL database added
- [ ] All environment variables configured
- [ ] Railway URL responds to `/health`
- [ ] Flutter app updated with Railway URL
- [ ] Flutter app connects successfully

---

## 🚨 **COMMON ISSUES & SOLUTIONS**

### **Issue: Build Fails**
- **Check**: Root directory is set to `/server`
- **Check**: All environment variables are added
- **Check**: PostgreSQL service is running

### **Issue: Flutter Can't Connect**
- **Check**: Railway URL is correct in `api_config.dart`
- **Check**: Using `https://` not `http://`
- **Check**: No typos in the URL

### **Issue: Database Errors**
- **Check**: PostgreSQL service is active
- **Check**: `DATABASE_URL` is automatically set by Railway
- **Check**: Prisma migrations ran successfully

---

## 🎯 **FINAL RESULT**

Your app will be live at: `https://your-project-name.up.railway.app`

**What you get:**
- ✅ Live NestJS API server
- ✅ PostgreSQL database
- ✅ Automatic deployments from GitHub
- ✅ HTTPS security
- ✅ Environment variables management
- ✅ Build and deployment logs
