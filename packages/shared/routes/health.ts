import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { redis } from '../db';
import { logger } from '../logger';

export const healthRouter = new OpenAPIHono();

const healthRoute = createRoute({
  method: 'get',
  path: '/health',
  description: 'Health check endpoint with Redis status',
  responses: {
    200: {
      description: 'Service healthy',
      content: {
        'application/json': {
          schema: z.object({
            status: z.literal('ok'),
            redis: z.literal('healthy'),
          }),
        },
      },
    },
    500: {
      description: 'Service or Redis unhealthy',
      content: {
        'application/json': {
          schema: z.object({
            status: z.literal('error'),
            redis: z.literal('unreachable'),
          }),
        },
      },
    },
  },
});

healthRouter.openapi(healthRoute, async (c) => {
  try {
    if (!redis.isOpen) await redis.connect();
    await redis.ping();
    return c.json({ status: 'ok' as const, redis: 'healthy' as const }, 200);
  } catch (error) {
    logger.error(error, 'unhealthy');
    return c.json(
      { status: 'error' as const, redis: 'unreachable' as const },
      500
    );
  }
});
