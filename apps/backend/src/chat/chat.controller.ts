import {
  Controller,
  Post,
  Body,
  Param,
  Sse,
  UseGuards,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Observable } from 'rxjs';
import { ChatService } from './chat.service';
import { SendMessageDto } from './dto/send-message.dto';
import { FirebaseAuthGuard } from '../common/guards/firebase-auth.guard';
import type { AuthenticatedUser } from '../common/guards/firebase-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('chat')
@ApiBearerAuth()
@UseGuards(FirebaseAuthGuard)
@Controller('sessions')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post(':sessionId/messages')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Send a message and receive SSE streaming response',
  })
  @Sse()
  async sendMessage(
    @Param('sessionId', ParseUUIDPipe) sessionId: string,
    @Body() dto: SendMessageDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<Observable<MessageEvent>> {
    return this.chatService.processMessage(
      sessionId,
      dto.content,
      user.id,
      dto.clientMessageId,
    );
  }
}
