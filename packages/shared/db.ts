import { createClient } from 'redis';
import { logger } from './logger';

const client = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
  socket: {
    reconnectStrategy: (retries) => new Error("Couldn't connect to database"),
  },
});

client.on('error', (err) => {
  logger.error(err, 'Redis Client Error');
});

export const redis = client;
