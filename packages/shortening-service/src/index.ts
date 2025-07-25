import { Hono } from 'hono';
import { healthRouter } from './routes/health';

const app = new Hono();

app.route('/health', healthRouter);

export default app;
