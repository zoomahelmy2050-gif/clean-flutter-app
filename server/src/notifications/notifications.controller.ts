import { Controller, Sse, UseGuards, Req, MessageEvent } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard.js';
import { NotificationsService } from './notifications.service.js';
import { Observable, map } from 'rxjs';

@Controller('notifications')
export class NotificationsController {
  constructor(private notifications: NotificationsService) {}

  @Sse('stream')
  @UseGuards(JwtGuard)
  stream(@Req() req: any): Observable<MessageEvent> {
    const userId = req.user?.sub as string;
    return this.notifications.stream(userId).pipe(map((data) => ({ data })));
  }
}
