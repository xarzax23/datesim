import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SessionsController } from './sessions.controller';
import { Session } from '../entities';

@Module({
  imports: [TypeOrmModule.forFeature([Session])],
  controllers: [SessionsController],
})
export class SessionsModule {}
