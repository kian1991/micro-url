import { Hono } from 'hono';
import { healthRouter } from './routes/health';
import { shortenRouter } from './routes/shorten';
import { errorMiddleware } from '../../shared/error-middleware';

const app = new Hono();

app.route('/health', healthRouter);
app.route('/shorten', shortenRouter);

app.onError(errorMiddleware);

export default app;
