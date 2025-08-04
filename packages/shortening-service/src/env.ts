import { z } from 'zod';

declare module 'bun' {
  interface Env {
    REDIS_URL: string;
    BASE_URL: string;
    PORT: number;
  }
}

const EnvSchema = z.object({
  REDIS_URL: z.url(),
  BASE_URL: z.url(),
  PORT: z.string(),
});

const parsedEnv = EnvSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error(
    `Error in .env: ${JSON.stringify(parsedEnv.error.issues, null, 2)}`
  );
  process.exit(1);
}

export const ENV = parsedEnv.data;
