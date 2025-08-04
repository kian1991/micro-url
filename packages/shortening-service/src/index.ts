import { Hono } from 'hono';
import { shortenRouter } from './routes/shorten';
import { errorMiddleware } from '../../shared/error-middleware';
import { healthRouter } from '../../shared/routes/health';
import { swaggerUI } from '@hono/swagger-ui';
import { OpenAPIHono } from '@hono/zod-openapi';

const app = new OpenAPIHono();

app.doc('/doc', {
  openapi: '3.0.0',
  info: {
    version: '1.0.0',
    title: 'Shortening Service',
  },
});

app.get('/doc-ui', swaggerUI({ url: '/doc' }));

app.route('/', healthRouter);
app.route('/', shortenRouter);

app.onError(errorMiddleware);

export default app;
