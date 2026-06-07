import { HttpStatus } from '@nestjs/common';
import { HTTP_CODE_METADATA } from '@nestjs/common/constants';
import { ChatController } from './chat.controller';

describe('ChatController', () => {
  it('returns HTTP 200 for the POST SSE endpoint', () => {
    const descriptor = Object.getOwnPropertyDescriptor(
      ChatController.prototype,
      'sendMessage',
    );
    if (typeof descriptor?.value !== 'function') {
      throw new Error('ChatController.sendMessage is not available');
    }

    const status = Reflect.getMetadata(
      HTTP_CODE_METADATA,
      descriptor.value as object,
    ) as unknown;

    expect(status).toBe(HttpStatus.OK);
  });
});
