import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatModule } from './chat/chat.module';
import { SessionsModule } from './sessions/sessions.module';
import { ScoringModule } from './scoring/scoring.module';
import { ScenariosModule } from './scenarios/scenarios.module';
import { AuthModule } from './auth/auth.module';
import { User, Session, Message } from './entities';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        url: config.get<string>('DATABASE_URL'),
        entities: [User, Session, Message],
        synchronize: config.get('NODE_ENV') !== 'production',
        logging: config.get('NODE_ENV') !== 'production',
      }),
    }),
    ChatModule,
    SessionsModule,
    ScoringModule,
    ScenariosModule,
    AuthModule,
  ],
})
export class AppModule {}
