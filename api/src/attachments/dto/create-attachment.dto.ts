import {
  IsEnum,
  IsOptional,
  IsDateString,
  IsString,
  MaxLength,
} from 'class-validator';
import { AttachmentKind } from '../attachment.entity.js';

export class CreateAttachmentDto {
  @IsEnum(AttachmentKind)
  kind: AttachmentKind;

  @IsOptional()
  @IsDateString()
  expirationDate?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
