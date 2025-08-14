import { z } from '@hono/zod-openapi';

export const ForwardParams = z.object({
  slug: z
    .string()
    .min(3)
    .openapi({
      param: {
        name: 'slug',
        in: 'path',
      },
      example: 'abc123',
    }),
});

export const ErrorResponse = z.object({
  error: z.string().openapi({
    example: 'Bad Request',
  }),
});
