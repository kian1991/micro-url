export async function shortenUrl(longUrl: string, apiKey?: string) {
  const res = await fetch('/api/shorten', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(apiKey ? { Authorization: `Bearer ${apiKey}` } : {}),
    },
    body: JSON.stringify({ url: longUrl }),
  });

  if (!res.ok) {
    throw new Error(`Failed to shorten: ${res.statusText}`);
  }

  return res.json() as Promise<{ shortUrl: string }>;
}
