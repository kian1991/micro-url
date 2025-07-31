import { z } from 'zod';

declare module 'bun' {
  interface Env {
    REDIS_URL: string;
  }
}

const EnvSchema = z.object({
  REDIS_URL: z.url(),
});

const parsedEnv = EnvSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error(
    `Error in .env: ${JSON.stringify(parsedEnv.error.issues, null, 2)}`
  );
  process.exit(1);
}

export const ENV = parsedEnv.data;
