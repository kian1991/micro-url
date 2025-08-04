import z from 'zod';
import { redis } from './db';

export type Url = string;
export type ShortUrl = string;
export type Slug = string;

export type UrlEntry = [url: Url, slug: Slug];

export type RedisClient = typeof redis;
