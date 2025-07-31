import { Hono } from 'hono';
import { healthRouter } from './routes/health';
import { ENV } from './env';

const app = new Hono();

app.route('/health', healthRouter);

console.log(ENV.REDIS_URL);

export default app;
