import z from 'zod';

export const ShortenRequest = z.object({
  longUrl: z.url(),
});
