import { Hono } from 'hono';
import { logger } from '../../../shared/logger';
import { redis } from '../../../shared/db';

export const healthRouter = new Hono();

healthRouter.get('/', async (c) => {
  try {
    if (!redis.isOpen) await redis.connect();
    await redis.ping();
    return c.json({ status: 'ok', redis: 'healthy' });
  } catch (error) {
    logger.error(error, 'unhealthy');
    return c.json({ status: 'error', redis: 'unreachable' }, 500);
  }
});
