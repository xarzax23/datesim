import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepo: Repository<User>,
  ) {}

  async findOrCreate(
    firebaseUid: string,
    email?: string,
    displayName?: string,
  ): Promise<User> {
    let user = await this.usersRepo.findOne({ where: { firebaseUid } });
    if (!user) {
      user = this.usersRepo.create({ firebaseUid, email, displayName });
      user = await this.usersRepo.save(user);
    }
    return user;
  }

  async findByFirebaseUid(firebaseUid: string): Promise<User | null> {
    return this.usersRepo.findOne({ where: { firebaseUid } });
  }
}
