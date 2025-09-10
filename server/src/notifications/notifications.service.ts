import { Injectable } from '@nestjs/common';
import { Observable, Subject } from 'rxjs';

export type NotificationEvent = {
  type: string;
  title?: string;
  message?: string;
  data?: any;
  timestamp?: number;
};

@Injectable()
export class NotificationsService {
  private subjects = new Map<string, Subject<NotificationEvent>>();

  private getSubject(userId: string): Subject<NotificationEvent> {
    let subj = this.subjects.get(userId);
    if (!subj) {
      subj = new Subject<NotificationEvent>();
      this.subjects.set(userId, subj);
    }
    return subj;
  }

  stream(userId: string): Observable<NotificationEvent> {
    return this.getSubject(userId).asObservable();
  }

  notify(userId: string, event: NotificationEvent) {
    const enriched: NotificationEvent = {
      timestamp: Date.now(),
      ...event,
    };
    this.getSubject(userId).next(enriched);
  }
}
