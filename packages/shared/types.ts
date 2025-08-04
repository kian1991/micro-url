import z from 'zod';
import { redis } from './db';
import { ShortenRequest } from './zod-schemas';

export type Url = string;
export type ShortUrl = string;
export type Slug = string;

export type UrlEntry = [url: Url, slug: Slug];

export type RedisClient = typeof redis;

// API
export type ShortenRequest = z.infer<typeof ShortenRequest>;
export type ShortenResponse = {
  shortUrl: ShortUrl;
};
