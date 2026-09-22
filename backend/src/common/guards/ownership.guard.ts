import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Request } from 'express';
import { InMemoryDbService } from '../../database/in-memory-db.service';
import { UserRole } from '../enums/user-role.enum';
import { AuthenticatedUser } from './jwt-auth.guard';

@Injectable()
export class OwnershipGuard implements CanActivate {
  constructor(private readonly dbService: InMemoryDbService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const user: AuthenticatedUser = (request as any).user;

    if (!user) {
      throw new ForbiddenException('Access denied: Authentication context missing');
    }

    // Determine target patient ID from route params or body
    const targetPatientId =
      request.params.patientId ||
      request.params.id ||
      request.body?.patientId;

    if (!targetPatientId) {
      // If no patient target is declared in the request, allow route to handle
      return true;
    }

    // 1. ADMIN has global oversight access
    if (user.role === UserRole.ADMIN) {
      return true;
    }

    // 2. PATIENT can ONLY access their own records
    if (user.role === UserRole.PATIENT) {
      if (user.userId !== targetPatientId) {
        throw new ForbiddenException(
          "Access denied: You do not have permission to access another patient's records.",
        );
      }
      return true;
    }

    // 3. CAREGIVER can ONLY access patients with an ACTIVE registered relationship
    if (user.role === UserRole.CAREGIVER) {
      const activeRel = await this.dbService.findActiveRelationship(
        user.userId,
        targetPatientId,
      );

      if (!activeRel) {
        throw new ForbiddenException(
          "Access denied: You are not authorized to access this patient's records.",
        );
      }
      return true;
    }

    throw new ForbiddenException('Access denied: Unauthorized relationship.');
  }
}
