import { beforeEach, describe, expect, it, mock } from 'bun:test';
import { SLUG_SEQUENCE, TEST_BASE_URL } from './constants';
import { createRedisMock } from './__mocks__/db';
import { createRandomBytesMock } from './__mocks__/crypto';
import { RedisClient } from '../types';
import { createSlugService } from '../slug';

// SETUP
// mocks
mock.module(
  '../db',
  mock(() => createRedisMock())
);

mock.module(
  'crypto',
  mock(() => createRandomBytesMock())
);

// Generate Slug
describe('Slug Service | generateSlug', () => {
  let slugService: ReturnType<typeof createSlugService>;
  let redis: RedisClient;

  beforeEach(async () => {
    // Imports
    const { redis: redisMock } = await import('../db');
    redis = redisMock;

    const { createSlugService } = await import('../slug');
    slugService = createSlugService(redis, TEST_BASE_URL);
  });

  it('generateSlug should generate a base62 encoded slug', async () => {
    expect(await slugService.generateSlug()).toBe(SLUG_SEQUENCE[0].slug);
  });
});

describe('Slug Service | checkSlug', async () => {
  let slugService: ReturnType<typeof createSlugService>;
  let redis: RedisClient;

  beforeEach(async () => {
    // Imports
    const { redis: redisMock } = await import('../db');
    redis = redisMock;

    const { createSlugService } = await import('../slug');
    slugService = createSlugService(redis, TEST_BASE_URL);
  });

  it('checkSlug returns true for existing slug', async () => {
    expect(await slugService.checkSlug(SLUG_SEQUENCE[1].slug)).toBe(true);
  });

  it('checkSlug returns false for non-existing slugs', async () => {
    expect(await slugService.checkSlug('does-not-exist')).toBe(false);
  });
});
