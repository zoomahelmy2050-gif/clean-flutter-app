import { IsEnum } from 'class-validator';

export enum ReportStatusDto {
  SUBMITTED = 'SUBMITTED',
  IN_PROGRESS = 'IN_PROGRESS',
  FIXED = 'FIXED',
}

export class UpdateReportStatusDto {
  @IsEnum(ReportStatusDto)
  status!: ReportStatusDto;
}
