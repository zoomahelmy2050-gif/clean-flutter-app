import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  try {
    console.log('Starting E2EE server...');
    console.log('Environment variables:', {
      PORT: process.env.PORT,
      NODE_ENV: process.env.NODE_ENV,
      DATABASE_URL: process.env.DATABASE_URL ? 'Set' : 'Not set',
      JWT_SECRET: process.env.JWT_SECRET ? 'Set' : 'Not set',
    });

    const app = await NestFactory.create(AppModule);
  
    // Manual CORS headers for preflight (defensive)
    const expressApp = (app as any).getHttpAdapter().getInstance();
    expressApp.use((req: any, res: any, next: any) => {
      res.setHeader('Access-Control-Allow-Origin', (req.headers.origin as string) || '*');
      res.setHeader('Vary', 'Origin');
      res.setHeader('Access-Control-Allow-Credentials', 'true');
      res.setHeader('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
      if (req.method === 'OPTIONS') {
        res.status(204).end();
        return;
      }
      next();
    });
  
    // Enable CORS
    const corsOrigins = process.env.CORS_ORIGINS 
      ? process.env.CORS_ORIGINS.split(',').map(origin => origin.trim())
      : ['http://localhost:3000', 'http://localhost:4000', 'https://citizen-fix-admin-dashboard.onrender.com'];
  
    console.log('CORS Origins:', corsOrigins);
  
    app.enableCors({
      origin: (origin, callback) => {
        // Allow requests with no origin (like mobile apps or Postman)
        if (!origin) return callback(null, true);
        
        if (corsOrigins.includes(origin)) {
          callback(null, true);
        } else {
          console.log(`CORS blocked origin: ${origin}`);
          callback(null, true); // For now, allow all origins to debug
        }
      },
      methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
      allowedHeaders: 'Origin, X-Requested-With, Content-Type, Accept, Authorization',
      credentials: true,
      preflightContinue: false,
      optionsSuccessStatus: 204,
    });
    
    // Global DTO validation
    app.useGlobalPipes(new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }));
  
    const port = process.env.PORT || 3000;
  
    console.log(`Attempting to bind to port ${port}...`);
  
    await app.listen(port, '0.0.0.0');
    console.log(`E2EE server successfully listening on http://0.0.0.0:${port}`);
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

bootstrap().catch(error => {
  console.error('Bootstrap failed:', error);
  process.exit(1);
});
