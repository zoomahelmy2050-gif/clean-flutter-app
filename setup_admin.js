const https = require('https');
const crypto = require('crypto');

const backendUrl = 'clean-flutter-app.onrender.com';
const email = 'env.hygiene@gmail.com';
const password = 'password';

// Function to make HTTPS request
function makeRequest(options, data) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                console.log(`Status: ${res.statusCode}`);
                try {
                    const parsed = JSON.parse(body);
                    resolve({ status: res.statusCode, data: parsed });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
                }
            });
        });
        
        req.on('error', reject);
        if (data) req.write(data);
        req.end();
    });
}

// Generate v2 password record
function createPasswordV2(password) {
    const salt = crypto.randomBytes(16);
    const iterations = 10000;
    
    // PBKDF2 - matching backend's implementation
    const key = crypto.pbkdf2Sync(Buffer.from(password, 'utf8'), salt, iterations, 32, 'sha256');
    
    // HMAC - matching backend's implementation
    const verifier = crypto.createHmac('sha256', salt).update(key).digest();
    
    const saltB64 = salt.toString('base64');
    const verifierB64 = verifier.toString('base64');
    
    return `v2:${saltB64}:${iterations}:${verifierB64}`;
}

async function setupAdmin() {
    console.log('=== Setting up Admin User on Render ===\n');
    
    // Step 1: Check health
    console.log('1. Checking backend health...');
    try {
        const healthOptions = {
            hostname: backendUrl,
            path: '/health',
            method: 'GET'
        };
        const health = await makeRequest(healthOptions);
        console.log('✅ Backend is healthy:', health.data);
    } catch (error) {
        console.log('❌ Health check failed:', error.message);
    }
    
    // Step 2: Register admin with proper v2 password
    console.log('\n2. Registering admin user...');
    const passwordRecordV2 = createPasswordV2(password);
    console.log('Generated v2 password record');
    
    const registerData = JSON.stringify({
        email: email,
        passwordRecordV2: passwordRecordV2
    });
    
    const registerOptions = {
        hostname: backendUrl,
        path: '/auth/register',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': registerData.length
        }
    };
    
    try {
        const register = await makeRequest(registerOptions, registerData);
        if (register.status === 201 || register.status === 200) {
            console.log('✅ Admin registered successfully!');
        } else if (register.status === 409 || (register.data && register.data.toString().includes('exists'))) {
            console.log('⚠️  Admin user already exists (this is OK)');
        } else {
            console.log('Registration response:', register.data);
        }
    } catch (error) {
        console.log('Registration error:', error.message);
    }
    
    // Step 3: Test login
    console.log('\n3. Testing login...');
    const loginData = JSON.stringify({
        email: email,
        password: password
    });
    
    const loginOptions = {
        hostname: backendUrl,
        path: '/auth/login',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': loginData.length
        }
    };
    
    try {
        const login = await makeRequest(loginOptions, loginData);
        if (login.status === 200 && login.data.accessToken) {
            console.log('✅ Login successful!');
            console.log('Token (first 30 chars):', login.data.accessToken.substring(0, 30) + '...');
            
            // Step 4: Test migration endpoint
            console.log('\n4. Testing migration endpoint...');
            const migrationOptions = {
                hostname: backendUrl,
                path: '/migrations/status',
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${login.data.accessToken}`
                }
            };
            
            try {
                const migration = await makeRequest(migrationOptions);
                if (migration.status === 200) {
                    console.log('✅ Migration endpoint working!');
                    console.log('Database connected:', migration.data.databaseConnected);
                }
            } catch (error) {
                console.log('Migration endpoint error:', error.message);
            }
        } else {
            console.log('❌ Login failed:', login.data);
        }
    } catch (error) {
        console.log('Login error:', error.message);
    }
    
    console.log('\n=====================================');
    console.log('CREDENTIALS FOR FLUTTER APP:');
    console.log('Email:', email);
    console.log('Password:', password);
    console.log('Backend URL:', `https://${backendUrl}`);
    console.log('=====================================\n');
}

setupAdmin().catch(console.error);
