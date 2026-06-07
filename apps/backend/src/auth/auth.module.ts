import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { User } from '../entities';
import { FirebaseAuthGuard } from '../common/guards/firebase-auth.guard';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [UsersService, FirebaseAuthGuard],
  exports: [UsersService, FirebaseAuthGuard],
})
export class AuthModule {}
