import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
} from 'typeorm';
import { User } from './user.entity';
import { Message } from './message.entity';

@Entity('sessions')
export class Session {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User, (user) => user.sessions)
  user!: User;

  @Column()
  userId!: string;

  @Column()
  scenarioId!: string;

  @Column({ default: 'easy' })
  difficulty!: string;

  @Column({ default: 'active' })
  status!: string; // active | completed | rejected | abandoned

  @Column({ type: 'jsonb', default: {} })
  state!: Record<string, unknown>;

  @Column({ type: 'float', nullable: true })
  overallScore?: number;

  @OneToMany(() => Message, (message) => message.session)
  messages!: Message[];

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
