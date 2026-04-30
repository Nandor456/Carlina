import { IsEnum, IsDateString } from 'class-validator';
import { DocumentType } from '../document.entity.js';

export class CreateDocumentDto {
  @IsEnum(DocumentType)
  documentType!: DocumentType;

  @IsDateString()
  issueDate!: string;

  @IsDateString()
  expirationDate!: string;
}
