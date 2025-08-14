import { errorMiddleware } from '../../shared/error-middleware';
import { healthRouter } from '../../shared/routes/health';
import { swaggerUI } from '@hono/swagger-ui';
import { OpenAPIHono } from '@hono/zod-openapi';
import { forwardRouter } from './routes/forward';

const app = new OpenAPIHono();

app.doc('/doc', {
  openapi: '3.0.0',
  info: {
    version: '1.0.0',
    title: 'Forwading Service',
  },
});

app.get('/doc-ui', swaggerUI({ url: '/doc' }));

app.route('/', healthRouter);
app.route('/', forwardRouter);

app.onError(errorMiddleware);

export default app;
