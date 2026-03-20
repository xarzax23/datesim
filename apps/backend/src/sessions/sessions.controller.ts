import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FirebaseAuthGuard } from '../common/guards/firebase-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Session } from '../entities';
import { IsNotEmpty, IsString, IsIn } from 'class-validator';

class CreateSessionDto {
  @IsString()
  @IsNotEmpty()
  scenarioId!: string;

  @IsString()
  @IsIn(['easy', 'medium', 'hard'])
  difficulty!: string;
}

@ApiTags('sessions')
@ApiBearerAuth()
@UseGuards(FirebaseAuthGuard)
@Controller('sessions')
export class SessionsController {
  constructor(
    @InjectRepository(Session)
    private sessionRepo: Repository<Session>,
  ) {}

  @Post()
  @ApiOperation({ summary: 'Create a new practice session' })
  async create(
    @Body() dto: CreateSessionDto,
    @CurrentUser() user: { uid: string },
  ) {
    const session = this.sessionRepo.create({
      userId: user.uid,
      scenarioId: dto.scenarioId,
      difficulty: dto.difficulty,
      status: 'active',
    });
    return this.sessionRepo.save(session);
  }

  @Get()
  @ApiOperation({ summary: 'List user sessions' })
  async list(@CurrentUser() user: { uid: string }) {
    return this.sessionRepo.find({
      where: { userId: user.uid },
      order: { createdAt: 'DESC' },
      take: 20,
    });
  }
}
