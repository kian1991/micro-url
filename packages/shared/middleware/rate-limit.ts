import type { Context, Next } from 'hono';
import { redis } from '../db';

const WINDOW = 60; // seconds
const MAX_REQ = 100; // requests per window per IP

export async function rateLimit(c: Context, next: Next) {
  let ip: string | undefined;
  // Try x-forwarded-for header
  const xff = c.req.header('x-forwarded-for');
  if (xff) {
    ip = xff.split(',')[0].trim();
  } else {
    // Try cf-connecting-ip header (Cloudflare etc.)
    const cfIp = c.req.raw.headers.get('cf-connecting-ip');
    if (cfIp) {
      ip = cfIp;
    } else {
      // Try x-real-ip header
      const realIp = c.req.raw.headers.get('x-real-ip');
      if (realIp) {
        ip = realIp;
      } else {
        ip = 'unknown';
      }
    }
  }

  const key = `ratelimit:${ip}`;
  if (!redis.isOpen) redis.connect();
  const count = await redis.incr(key);

  if (count === 1) {
    await redis.expire(key, WINDOW);
  }

  if (count > MAX_REQ) {
    return c.json({ error: 'Too Many Requests' }, 429);
  }

  await next();
}
