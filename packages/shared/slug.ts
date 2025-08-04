import { ReplyUnion } from '@redis/client/dist/lib/RESP/types';
import { RedisClient, ShortUrl, Slug, Url, UrlEntry } from './types';
import base from 'base-x';
import { randomBytes } from 'crypto';
import { logger } from './logger';
import { redis } from './db';
import { sl } from 'zod/v4/locales/index.cjs';
import { ERROR_MESSAGES } from './constants';

const BASE62 = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
const base62 = base(BASE62);
const RANDOM_BYTE_COUNT = 4;

export function createSlugService(db: RedisClient, baseUrl: string) {
  // Just to glue together the baseUrl with the slug as its used in multiple locations
  function constructResolvedUrl(slug: Slug): string {
    return `${baseUrl}/${slug}`;
  }
  /**
   * The Slug generation function returns slugs in the Format: 0Ab1c2
   *
   * @returns slug as string
   */
  async function generateSlug(): Promise<Slug> {
    const randBytes = randomBytes(RANDOM_BYTE_COUNT);
    const slug = base62.encode(Buffer.from(randBytes));

    const slugAlreadyExists = await checkSlug(slug);
    if (slugAlreadyExists) {
      logger.warn({ slug, reason: 'collision' }, 'Slug already exists');
      return await generateSlug(); // await bc otherwise a promise would be returned!
    }

    return slug;
  }

  /**
   * Checks if a slug exists via bloom filter against a database i.e. Redis (Could return false positives but never negatives)
   * @param slug
   * @returns true if a given slug definitely exists
   */
  async function checkSlug(slug: string): Promise<boolean> {
    return db.bf.exists('slug-bloom', slug);
  }

  async function _storeEntry(entry: UrlEntry): Promise<ReplyUnion[]> {
    const [url, slug] = entry;
    return await db
      .multi()
      .set(`url:${url}`, slug)
      .set(`slug:${slug}`, url)
      .exec();
  }

  async function storeUrl(url: Url): Promise<ShortUrl> {
    if (!db.isOpen) await db.connect();
    // check for existing url and return the slug if found
    let slug = await db.get(`url:${url}`);

    if (slug) return constructResolvedUrl(slug);

    slug = await generateSlug();

    // res is an array bc of redis.multi being a transaction
    const res = await _storeEntry([url, slug]);

    // Very rarely res can be null. Let's be defensive about that. (for example if WATCH is failing)
    if (!res) {
      logger.fatal({ url, slug }, ERROR_MESSAGES.REDIS.TRANSACTION_NULL);
      throw new Error(ERROR_MESSAGES.REDIS.TRANSACTION_NULL);
    }

    for (const r of res) {
      if (r instanceof Error) {
        logger.error(
          { error: r, url, slug },
          ERROR_MESSAGES.REDIS.TRANSACTION_ERROR
        );

        throw r;
      }
    }

    return constructResolvedUrl(slug);
  }

  async function resolveSlug(slug: Slug): Promise<Url> {
    if (!db.isOpen) await db.connect();

    const entry = await db.get(`slug:${slug}`);

    if (!entry) {
      logger.warn({ slug, reason: ERROR_MESSAGES.SLUG.NOT_FOUND });
      throw new Error(ERROR_MESSAGES.SLUG.NOT_FOUND);
    }

    return entry;
  }

  return {
    generateSlug,
    checkSlug,
    storeUrl,
    resolveSlug,
  };
}
