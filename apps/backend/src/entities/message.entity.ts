import {
  Entity,
  Index,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
} from 'typeorm';
import { Session } from './session.entity';

@Entity('messages')
@Index(['sessionId', 'clientMessageId'], { unique: true })
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => Session, (session) => session.messages)
  session!: Session;

  @Column()
  sessionId!: string;

  @Column({ nullable: true })
  clientMessageId?: string;

  @Column()
  turnIndex!: number;

  @Column()
  role!: string; // user | assistant

  @Column('text')
  content!: string;

  @Column({ type: 'jsonb', nullable: true })
  scorecard?: Record<string, unknown>;

  @Column({ type: 'int', nullable: true })
  tokensInput?: number;

  @Column({ type: 'int', nullable: true })
  tokensOutput?: number;

  @CreateDateColumn()
  createdAt!: Date;
}
