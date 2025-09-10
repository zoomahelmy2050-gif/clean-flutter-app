var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { IsString, IsOptional, IsNumber, Min, Max } from 'class-validator';
import { Transform, Type } from 'class-transformer';
export class CreateReportDto {
    issueType;
    description;
    photoUrl;
    latitude;
    longitude;
}
__decorate([
    IsString(),
    Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)),
    __metadata("design:type", String)
], CreateReportDto.prototype, "issueType", void 0);
__decorate([
    IsString(),
    Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)),
    __metadata("design:type", String)
], CreateReportDto.prototype, "description", void 0);
__decorate([
    IsOptional(),
    IsString(),
    Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)),
    __metadata("design:type", String)
], CreateReportDto.prototype, "photoUrl", void 0);
__decorate([
    Type(() => Number),
    IsNumber(),
    Min(-90),
    Max(90),
    __metadata("design:type", Number)
], CreateReportDto.prototype, "latitude", void 0);
__decorate([
    Type(() => Number),
    IsNumber(),
    Min(-180),
    Max(180),
    __metadata("design:type", Number)
], CreateReportDto.prototype, "longitude", void 0);
//# sourceMappingURL=create-report.dto.js.map