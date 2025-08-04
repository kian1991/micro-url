import { Context } from 'hono';
import z, { ZodError } from 'zod';
import { HTTPException } from 'hono/http-exception';
import { logger } from './logger';

export const errorMiddleware = (error: Error, c: Context) => {
  console.log(error);
  logger.error({ request: c.req, header: c.header, error }, 'Request Error');

  // handle httpError
  if (error instanceof HTTPException) {
    return c.json({ error: error.message }, error.status);
  }

  // handle validation error
  if (error instanceof ZodError)
    return c.json({ error: z.treeifyError(error) }, 400);

  // handle Redis Errors

  if (error instanceof SyntaxError) {
    // handle syntax error
    return c.json({ error: 'Invalid JSON' }, 400);
  }

  return c.json({ error: 'Internal server error' }, 500);
};
