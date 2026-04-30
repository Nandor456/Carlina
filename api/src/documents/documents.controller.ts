import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  ParseUUIDPipe,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import type { Request } from 'express';
import { DocumentsService } from './documents.service.js';
import { CreateDocumentDto } from './dto/create-document.dto.js';
import { UpdateDocumentDto } from './dto/update-document.dto.js';
import { AuthenticatedGuard } from '../auth/guards/authenticated.guard.js';
import { User } from '../users/user.entity.js';

@UseGuards(AuthenticatedGuard)
@Controller('vehicles/:vehicleId/documents')
export class DocumentsController {
  constructor(private readonly documentsService: DocumentsService) {}

  @Get()
  findAll(
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Req() req: Request,
  ) {
    return this.documentsService.findAllForVehicle(
      vehicleId,
      (req.user as User).id,
    );
  }

  @Get(':id')
  findOne(@Param('id', ParseUUIDPipe) id: string, @Req() req: Request) {
    return this.documentsService.findOne(id, (req.user as User).id);
  }

  @Post()
  create(
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Body() dto: CreateDocumentDto,
    @Req() req: Request,
  ) {
    return this.documentsService.create((req.user as User).id, vehicleId, dto);
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateDocumentDto,
    @Req() req: Request,
  ) {
    return this.documentsService.update(id, (req.user as User).id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id', ParseUUIDPipe) id: string, @Req() req: Request) {
    return this.documentsService.remove(id, (req.user as User).id);
  }
}
