import { createSlugService } from '../../../shared/slug';
import { redis } from '../../../shared/db';
import { ENV } from '../../../shared/env';
import { createRoute, OpenAPIHono } from '@hono/zod-openapi';
import { ErrorResponse, ShortenRequest, ShortenResponse } from '../schemas';

export const shortenRouter = new OpenAPIHono();

const slugService = createSlugService(redis, ENV.BASE_URL);

const shortenRoute = createRoute({
  method: 'post',
  path: '/shorten',
  request: {
    body: {
      content: {
        'application/json': {
          schema: ShortenRequest,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Shortened URL response',
      content: {
        'application/json': {
          schema: ShortenResponse,
        },
      },
    },
    400: {
      description: 'Error Response',
      content: {
        'application/json': {
          schema: ErrorResponse,
        },
      },
    },
  },
});

shortenRouter.openapi(shortenRoute, async (c) => {
  const { longUrl } = c.req.valid('json');
  const shortUrl = await slugService.storeUrl(longUrl);
  return c.json({ shortUrl }, 200);
});
