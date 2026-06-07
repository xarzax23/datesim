import {
  BadRequestException,
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FirebaseAuthGuard } from '../common/guards/firebase-auth.guard';
import type { AuthenticatedUser } from '../common/guards/firebase-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Message, Session } from '../entities';
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
    @InjectRepository(Message)
    private messageRepo: Repository<Message>,
  ) {}

  @Post()
  @ApiOperation({ summary: 'Create a new practice session' })
  async create(
    @Body() dto: CreateSessionDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    const session = this.sessionRepo.create({
      userId: user.id,
      scenarioId: dto.scenarioId,
      difficulty: dto.difficulty,
      status: 'active',
    });
    return this.sessionRepo.save(session);
  }

  @Get()
  @ApiOperation({ summary: 'List user sessions' })
  async list(@CurrentUser() user: AuthenticatedUser) {
    return this.sessionRepo.find({
      where: { userId: user.id },
      order: { createdAt: 'DESC' },
      take: 20,
    });
  }

  @Patch(':sessionId/complete')
  @ApiOperation({ summary: 'Complete an active practice session' })
  async complete(
    @Param('sessionId', ParseUUIDPipe) sessionId: string,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    const session = await this.sessionRepo.findOne({
      where: { id: sessionId, userId: user.id },
    });

    if (!session) {
      throw new NotFoundException('Session not found');
    }
    if (session.status === 'completed') {
      return session;
    }
    if (session.status !== 'active') {
      throw new BadRequestException('Only active sessions can be completed');
    }

    const messages = await this.messageRepo.find({
      where: { sessionId },
      order: { turnIndex: 'ASC' },
    });
    if (!messages.some((message) => message.role === 'user')) {
      throw new BadRequestException(
        'Complete at least one conversation turn first',
      );
    }

    const overallScores = messages
      .map((message) => message.scorecard?.overall)
      .filter((score): score is number => typeof score === 'number');
    const overallScore =
      overallScores.length > 0
        ? Math.round(
            (overallScores.reduce((sum, score) => sum + score, 0) /
              overallScores.length) *
              10,
          ) / 10
        : undefined;

    session.status = 'completed';
    session.overallScore = overallScore;
    return this.sessionRepo.save(session);
  }
}
