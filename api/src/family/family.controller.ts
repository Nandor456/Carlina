import {
  Controller,
  Get,
  Post,
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
import { FamilyService } from './family.service.js';
import { InviteDto } from './dto/invite.dto.js';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard.js';
import { User } from '../users/user.entity.js';

@UseGuards(JwtAuthGuard)
@Controller('family')
export class FamilyController {
  constructor(private readonly familyService: FamilyService) {}

  // ── Invites ──────────────────────────────────────────────────

  @Post('invite')
  sendInvite(@Body() dto: InviteDto, @Req() req: Request) {
    return this.familyService.sendInvite((req.user as User).id, dto.email);
  }

  @Get('invites/received')
  getReceivedInvites(@Req() req: Request) {
    return this.familyService.getReceivedInvites((req.user as User).id);
  }

  @Get('invites/sent')
  getSentInvites(@Req() req: Request) {
    return this.familyService.getSentInvites((req.user as User).id);
  }

  @Post('invites/:linkId/accept')
  @HttpCode(HttpStatus.NO_CONTENT)
  acceptInvite(
    @Param('linkId', ParseUUIDPipe) linkId: string,
    @Req() req: Request,
  ) {
    return this.familyService.acceptInvite(linkId, (req.user as User).id);
  }

  @Post('invites/:linkId/decline')
  @HttpCode(HttpStatus.NO_CONTENT)
  declineInvite(
    @Param('linkId', ParseUUIDPipe) linkId: string,
    @Req() req: Request,
  ) {
    return this.familyService.declineInvite(linkId, (req.user as User).id);
  }

  // ── Members ──────────────────────────────────────────────────

  @Get('members')
  getMembers(@Req() req: Request) {
    return this.familyService.getAcceptedMembers((req.user as User).id);
  }

  @Delete('members/:linkId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeLink(
    @Param('linkId', ParseUUIDPipe) linkId: string,
    @Req() req: Request,
  ) {
    return this.familyService.removeLink(linkId, (req.user as User).id);
  }

  @Get('members/:memberId/vehicles')
  getMemberVehicles(
    @Param('memberId', ParseUUIDPipe) memberId: string,
    @Req() req: Request,
  ) {
    return this.familyService.getMemberVehicles(
      memberId,
      (req.user as User).id,
    );
  }
}
