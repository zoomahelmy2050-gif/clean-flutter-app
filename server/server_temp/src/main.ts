import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';

async function bootstrap() {
  try {
    console.log('Starting E2EE server...');
    console.log('Environment variables:', {
      PORT: process.env.PORT,
      NODE_ENV: process.env.NODE_ENV,
      DATABASE_URL: process.env.DATABASE_URL ? 'Set' : 'Not set',
      JWT_SECRET: process.env.JWT_SECRET ? 'Set' : 'Not set'
    });

    const app = await NestFactory.create(AppModule, { logger: ['log', 'error', 'warn'] });
    app.enableCors();
    
    const port = process.env.PORT ? Number(process.env.PORT) : 3000;
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
