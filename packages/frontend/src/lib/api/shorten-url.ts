const BASE_URL = import.meta.env.VITE_API_BASE_URL;

export async function shortenUrl(longUrl: string, apiKey?: string) {
  const res = await fetch(`${BASE_URL}/shorten`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(apiKey ? { Authorization: `Bearer ${apiKey}` } : {}),
    },
    body: JSON.stringify({ longUrl: longUrl }),
  });

  if (!res.ok) {
    throw new Error(`Failed to shorten: ${res.statusText}`);
  }

  return res.json() as Promise<{ shortUrl: string }>;
}
