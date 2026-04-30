import { IsDateString, IsOptional } from 'class-validator';

export class UpdateDocumentDto {
  @IsDateString()
  @IsOptional()
  issueDate?: string;

  @IsDateString()
  @IsOptional()
  expirationDate?: string;
}
