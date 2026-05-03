import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FamilyLink, FamilyLinkStatus } from './family-link.entity.js';
import { Vehicle } from '../vehicles/vehicle.entity.js';
import { User } from '../users/user.entity.js';

@Injectable()
export class FamilyService {
  constructor(
    @InjectRepository(FamilyLink)
    private readonly linksRepo: Repository<FamilyLink>,
    @InjectRepository(Vehicle)
    private readonly vehiclesRepo: Repository<Vehicle>,
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
  ) {}

  async sendInvite(requesterId: string, email: string): Promise<FamilyLink> {
    const addressee = await this.usersRepo.findOne({ where: { email } });
    if (!addressee) throw new NotFoundException('No user found with that email');
    if (addressee.id === requesterId)
      throw new BadRequestException('You cannot invite yourself');

    const existing = await this.linksRepo.findOne({
      where: [
        { requesterId, addresseeId: addressee.id },
        { requesterId: addressee.id, addresseeId: requesterId },
      ],
    });
    if (existing)
      throw new BadRequestException('A link already exists with this user');

    const link = this.linksRepo.create({
      requesterId,
      addresseeId: addressee.id,
      status: FamilyLinkStatus.PENDING,
    });
    return this.linksRepo.save(link);
  }

  async getAcceptedMembers(userId: string) {
    const links = await this.linksRepo.find({
      where: [
        { requesterId: userId, status: FamilyLinkStatus.ACCEPTED },
        { addresseeId: userId, status: FamilyLinkStatus.ACCEPTED },
      ],
      relations: ['requester', 'addressee'],
    });

    return links.map((link) => {
      const member =
        link.requesterId === userId ? link.addressee : link.requester;
      return {
        linkId: link.id,
        id: member.id,
        email: member.email,
        fullName: member.fullName,
        avatarUrl: member.avatarUrl,
      };
    });
  }

  async getReceivedInvites(userId: string) {
    const links = await this.linksRepo.find({
      where: { addresseeId: userId, status: FamilyLinkStatus.PENDING },
      relations: ['requester'],
    });
    return links.map((link) => ({
      linkId: link.id,
      id: link.requester.id,
      email: link.requester.email,
      fullName: link.requester.fullName,
      avatarUrl: link.requester.avatarUrl,
    }));
  }

  async getSentInvites(userId: string) {
    const links = await this.linksRepo.find({
      where: { requesterId: userId, status: FamilyLinkStatus.PENDING },
      relations: ['addressee'],
    });
    return links.map((link) => ({
      linkId: link.id,
      id: link.addressee.id,
      email: link.addressee.email,
      fullName: link.addressee.fullName,
      avatarUrl: link.addressee.avatarUrl,
    }));
  }

  async acceptInvite(linkId: string, userId: string): Promise<void> {
    const link = await this.linksRepo.findOne({ where: { id: linkId } });
    if (!link) throw new NotFoundException('Invite not found');
    if (link.addresseeId !== userId) throw new ForbiddenException();
    if (link.status !== FamilyLinkStatus.PENDING)
      throw new BadRequestException('Invite already handled');
    link.status = FamilyLinkStatus.ACCEPTED;
    await this.linksRepo.save(link);
  }

  async declineInvite(linkId: string, userId: string): Promise<void> {
    const link = await this.linksRepo.findOne({ where: { id: linkId } });
    if (!link) throw new NotFoundException('Invite not found');
    if (link.addresseeId !== userId) throw new ForbiddenException();
    await this.linksRepo.remove(link);
  }

  async removeLink(linkId: string, userId: string): Promise<void> {
    const link = await this.linksRepo.findOne({ where: { id: linkId } });
    if (!link) throw new NotFoundException('Link not found');
    if (link.requesterId !== userId && link.addresseeId !== userId)
      throw new ForbiddenException();
    await this.linksRepo.remove(link);
  }

  async getMemberVehicles(memberId: string, requesterId: string) {
    const link = await this.linksRepo.findOne({
      where: [
        {
          requesterId,
          addresseeId: memberId,
          status: FamilyLinkStatus.ACCEPTED,
        },
        {
          requesterId: memberId,
          addresseeId: requesterId,
          status: FamilyLinkStatus.ACCEPTED,
        },
      ],
    });
    if (!link) throw new ForbiddenException('Not linked to this user');

    const vehicles = await this.vehiclesRepo.find({
      where: { userId: memberId },
      relations: ['documents'],
      order: { createdAt: 'ASC' },
    });

    // Null out image paths — family members use a different endpoint for images
    return vehicles.map((v) => {
      v.imagePath = null;
      v.imageMimeType = null;
      return v;
    });
  }
}
