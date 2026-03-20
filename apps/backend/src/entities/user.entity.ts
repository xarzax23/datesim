import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Session } from './session.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  firebaseUid!: string;

  @Column({ nullable: true })
  email?: string;

  @Column({ nullable: true })
  displayName?: string;

  @Column({ nullable: true })
  locale?: string;

  @Column({ type: 'jsonb', default: {} })
  privacySettings!: Record<string, unknown>;

  @Column({ default: 'free' })
  plan!: string;

  @OneToMany(() => Session, (session) => session.user)
  sessions!: Session[];

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
