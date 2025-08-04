export const ERROR_MESSAGES = {
  SLUG: {
    NOT_FOUND: 'Slug not found',
  },
  REDIS: {
    TRANSACTION_ERROR: 'Redis transaction contained error',
    TRANSACTION_NULL: 'Unexpected null result from Redis transaction',
  },
} as const;
