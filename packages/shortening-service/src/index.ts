import { Hono } from 'hono';
import { shortenRouter } from './routes/shorten';
import { errorMiddleware } from '../../shared/middleware/errors';
import { healthRouter } from '../../shared/routes/health';
import { swaggerUI } from '@hono/swagger-ui';
import { OpenAPIHono } from '@hono/zod-openapi';
import { rateLimit } from '../../shared/middleware/rate-limit';

const app = new OpenAPIHono();

// Redis based Rate Limiter
app.use('*', rateLimit);

// doc endpoints should only be visible in dev/stage environments
if (process.env.NODE_ENV !== 'production') {
  app.doc('/doc', {
    openapi: '3.0.0',
    info: {
      version: '1.0.0',
      title: 'Shortening Service',
    },
  });

  app.get('/doc-ui', swaggerUI({ url: '/doc' }));
}

app.route('/', healthRouter);
app.route('/', shortenRouter);

app.onError(errorMiddleware);

export default {
  port: process.env.PORT ?? 3000,
  fetch: app.fetch,
  hostname: '0.0.0.0',
};
