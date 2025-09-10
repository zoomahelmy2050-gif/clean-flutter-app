var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { Injectable } from '@nestjs/common';
import { Subject } from 'rxjs';
let NotificationsService = class NotificationsService {
    subjects = new Map();
    getSubject(userId) {
        let subj = this.subjects.get(userId);
        if (!subj) {
            subj = new Subject();
            this.subjects.set(userId, subj);
        }
        return subj;
    }
    stream(userId) {
        return this.getSubject(userId).asObservable();
    }
    notify(userId, event) {
        const enriched = {
            timestamp: Date.now(),
            ...event,
        };
        this.getSubject(userId).next(enriched);
    }
};
NotificationsService = __decorate([
    Injectable()
], NotificationsService);
export { NotificationsService };
//# sourceMappingURL=notifications.service.js.map