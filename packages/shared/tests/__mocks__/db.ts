import { mock } from 'bun:test';
import { RedisArgument } from 'redis';
import { SLUG_SEQUENCE, TEST_URL } from '../constants';

export function createRedisMock(overrides = {}) {
  const redisTransaction = {
    set: mock((_key: string) => redisTransaction),
    exec: mock(async () => ['OK', 'OK']),
  };

  return {
    redis: {
      get: mock(async (key: RedisArgument) => {
        return key === SLUG_SEQUENCE[1].slug ? TEST_URL : null;
      }),
      bf: {
        exists: mock(async (_key: RedisArgument, item: RedisArgument) => {
          return item === SLUG_SEQUENCE[1].slug;
        }),
      },
      multi: mock(() => redisTransaction),
      ...overrides,
    },
  };
}
