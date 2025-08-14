import { createSlugService } from '../../../shared/slug';
import { redis } from '../../../shared/db';
import { ENV } from '../../../shared/env';
import { createRoute, OpenAPIHono, z } from '@hono/zod-openapi';
import { ErrorResponse } from '../schemas';

export const forwardRouter = new OpenAPIHono();

const slugService = createSlugService(redis, ENV.BASE_URL);

const redirectRoute = createRoute({
  method: 'get',
  path: '/{slug}',
  request: {
    params: z.object({
      slug: z.string().openapi({
        param: {
          name: 'slug',
          in: 'path',
          required: true,
        },
        example: 'abc123',
        description: 'Short URL slug',
      }),
    }),
  },
  responses: {
    302: {
      description: 'Redirect to original URL',
      headers: {
        Location: {
          description: 'Target redirect URL',
        },
      },
    },
    404: {
      description: 'Slug not found',
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

forwardRouter.openapi(redirectRoute, async (c) => {
  const { slug } = c.req.valid('param');
  const longUrl = await slugService.resolveSlug(slug);

  if (!longUrl) c.notFound();
  return c.redirect(longUrl, 302);
});
