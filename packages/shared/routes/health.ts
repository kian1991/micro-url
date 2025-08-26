import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { redis } from '../db';
import { logger } from '../logger';

export const healthRouter = new OpenAPIHono();

// Simple health check (liveness)
const healthRoute = createRoute({
  method: 'get',
  path: '/health',
  description: 'Defaul health check for Loadbalancer etc.',
  responses: {
    200: {
      description: 'Service is alive',
      content: {
        'application/json': {
          schema: z.object({
            status: z.literal('ok'),
          }),
        },
      },
    },
  },
});

healthRouter.openapi(healthRoute, (c) => {
  return c.json({ status: 'ok' as const }, 200);
});

// Readiness check with Redis
const readinessRoute = createRoute({
  method: 'get',
  path: '/ready',
  description: 'Readiness check with Redis',
  responses: {
    200: {
      description: 'Ready and Redis healthy',
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
      description: 'Not ready (Redis unreachable)',
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

healthRouter.openapi(readinessRoute, async (c) => {
  try {
    if (!redis.isOpen) await redis.connect();
    await redis.ping();
    return c.json({ status: 'ok' as const, redis: 'healthy' as const }, 200);
  } catch (error) {
    logger.error(error, 'readiness unhealthy');
    return c.json(
      { status: 'error' as const, redis: 'unreachable' as const },
      500
    );
  }
});
