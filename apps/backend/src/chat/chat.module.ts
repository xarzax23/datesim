import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { ScoringModule } from '../scoring/scoring.module';
import { Session, Message } from '../entities';

@Module({
  imports: [TypeOrmModule.forFeature([Session, Message]), ScoringModule],
  controllers: [ChatController],
  providers: [ChatService],
})
export class ChatModule {}
