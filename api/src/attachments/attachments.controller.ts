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
  Res,
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Request, Response } from 'express';
import { AttachmentsService } from './attachments.service.js';
import { CreateAttachmentDto } from './dto/create-attachment.dto.js';
import { UpdateAttachmentDto } from './dto/update-attachment.dto.js';
import { AuthenticatedGuard } from '../auth/guards/authenticated.guard.js';
import { User } from '../users/user.entity.js';

const MAX_FILE_SIZE = 15 * 1024 * 1024; // 15 MB

@UseGuards(AuthenticatedGuard)
@Controller('vehicles/:vehicleId/attachments')
export class AttachmentsController {
  constructor(private readonly attachmentsService: AttachmentsService) {}

  @Get()
  findAll(
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Req() req: Request,
  ) {
    return this.attachmentsService.findAllForVehicle(vehicleId, (req.user as User).id);
  }

  @Get(':id')
  findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: Request,
  ) {
    return this.attachmentsService.findOne(id, (req.user as User).id);
  }

  @Get(':id/file')
  async streamFile(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() req: Request,
    @Res() res: Response,
  ) {
    await this.attachmentsService.streamFile(id, (req.user as User).id, res);
  }

  @Post()
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: MAX_FILE_SIZE } }),
  )
  create(
    @Param('vehicleId', ParseUUIDPipe) vehicleId: string,
    @Body() dto: CreateAttachmentDto,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Req() req: Request,
  ) {
    if (!file) throw new BadRequestException('No file uploaded');
    return this.attachmentsService.create(
      (req.user as User).id,
      vehicleId,
      dto,
      file,
    );
  }

  @Patch(':id')
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAttachmentDto,
    @Req() req: Request,
  ) {
    return this.attachmentsService.update(id, (req.user as User).id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id', ParseUUIDPipe) id: string, @Req() req: Request) {
    return this.attachmentsService.remove(id, (req.user as User).id);
  }
}
