import { z } from '@hono/zod-openapi';

export const ShortenRequest = z.object({
  longUrl: z.url().openapi({
    description: 'The long URL to be shortened',
    example: 'https://example.com/some/long/url',
  }),
});

export const ShortenResponse = z.object({
  shortUrl: z.string().openapi({
    description: 'The shortened URL',
    example: 'https://short.ly/abc123',
  }),
});

export const ErrorResponse = z.object({
  error: z.string().openapi({
    example: 'Bad Request',
  }),
});

export type ShortenRequest = z.infer<typeof ShortenRequest>;
export type ShortenResponse = z.infer<typeof ShortenResponse>;
