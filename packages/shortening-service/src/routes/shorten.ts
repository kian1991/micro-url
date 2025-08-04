import { Hono } from 'hono';
import { ShortenRequest } from '../../../shared/zod-schemas';
import { createSlugService } from '../../../shared/slug';
import { redis } from '../../../shared/db';
import { ENV } from '../env';
import { ShortenResponse } from '../../../shared/types';

export const shortenRouter = new Hono();

const slugService = createSlugService(redis, ENV.BASE_URL);

shortenRouter.post('/', async (c) => {
  const { longUrl } = ShortenRequest.parse(await c.req.json());

  const shortUrl = await slugService.storeUrl(longUrl);

  return c.json<ShortenResponse>({ shortUrl });
});
