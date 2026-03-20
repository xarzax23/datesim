import {
  Controller,
  Post,
  Body,
  Param,
  Sse,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Observable } from 'rxjs';
import { ChatService } from './chat.service';
import { SendMessageDto } from './dto/send-message.dto';
import { FirebaseAuthGuard } from '../common/guards/firebase-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('chat')
@ApiBearerAuth()
@UseGuards(FirebaseAuthGuard)
@Controller('sessions')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post(':sessionId/messages')
  @ApiOperation({ summary: 'Send a message and receive SSE streaming response' })
  @Sse()
  async sendMessage(
    @Param('sessionId', ParseUUIDPipe) sessionId: string,
    @Body() dto: SendMessageDto,
    @CurrentUser() user: { uid: string },
  ): Promise<Observable<MessageEvent>> {
    return this.chatService.processMessage(sessionId, dto.content, user.uid);
  }
}
