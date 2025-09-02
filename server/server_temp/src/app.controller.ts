import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('/')
  root() {
    return { status: 'ok', name: 'e2ee-server' };
  }

  @Get('/health')
  health() {
    return { status: 'healthy' };
  }
}
