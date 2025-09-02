<script lang="ts">
  import { onMount } from 'svelte';
  import Input from './components/Input.svelte';
  import Button from './components/Button.svelte';
  import Message from './components/Message.svelte';
  import { shortenUrl } from './lib/api/shorten-url';

  let apiKey = $state('');
  let droppedUrl = $state('');
  let shortUrlResult = $state('');

  const AUTH_ENABLED: boolean =
    import.meta.env.VITE_AUTH_ENABLED === 'true' || false;

  $inspect(AUTH_ENABLED);

  onMount(() => {
    const storedApiKey = localStorage.getItem('api-key');
    if (storedApiKey) apiKey = storedApiKey;
  });

  $effect(() => {
    localStorage.setItem('api-key', apiKey);
  });

  const handleShorten = async (e: SubmitEvent) => {
    e.preventDefault();
    console.log(`Input: ${droppedUrl}`);
    const { shortUrl } = await shortenUrl(droppedUrl);
    shortUrlResult = shortUrl;
  };
</script>

<main class="main">
  <div class="container">
    <div class="hero">
      <span class="logo">xoxo Murl</span>

      <h1 class="header" style="font-family: 'Ephesis'">Micro url</h1>
      <div>
        The real story behind this project is not the button or the short links
        you see. It lies in the architecture that powers it.
        <br />

        What looks like a minimal app is actually backed by:
        <ul>
          <li>Edge routing with CloudFront and Lambda@Edge</li>
          <li>
            CI/CD Pipelines with automated tests and deployments using GitHub
            Actions
          </li>
          <li>
            Horizontally scalable ECS services for shortening and forwarding
          </li>
          <li>Redis as a fast key-value store for lookups in milliseconds</li>
          <li>Terraform IaC for reproducible, automated deployments</li>
          <li>S3 + CloudFront for a globally distributed frontend</li>
          <li>
            ACM certificates + Cloudflare for secure, short custom domains
          </li>
          <li>Lightweight Frontend built with Svelte</li>
        </ul>
        This setup can handle millions of requests while staying lightweight and
        cost-efficient. It scales out horizontally, survives traffic spikes, and
        keeps latency low no matter where requests come from.
        <br />
        <br />
        Check out the
        <a
          href="https://github.com/kian1991/micro-url"
          target="_blank"
          rel="noopener">GitHub repo</a
        >
        for the full source code and more details.
      </div>
    </div>
    <form onsubmit={handleShorten} class="input__area">
      <h1>Drop-In</h1>
      <Input
        type="url"
        required
        placeholder="https://pretty-long.url/that/loves/to/be/shrinked"
        bind:value={droppedUrl}
      />
      {#if AUTH_ENABLED}
        <Input type="text" placeholder="Enter API Key." bind:value={apiKey} />
      {/if}
      <Button type="submit">SHORTEN</Button>
      {#if shortUrlResult}
        <Message message={shortUrlResult} style="margin-top: 2rem;"></Message>
      {/if}
    </form>
  </div>
</main>

<style>
  .main {
    background-color: var(--color-background);
    min-height: 100vh;
  }

  .container {
    width: 100%;
    display: flex;
    border-radius: 15px;
  }

  .header {
    color: var(--color-headline);
    font-size: 2.5em;
  }

  a {
    color: var(--color-headline);
    font-weight: 600;
    text-decoration: underline;
  }

  .hero {
    width: 100%;
    padding: 6rem 5rem;
    min-height: 100vh;
    background: var(--gradient);
    color: var(--color-paragraph);

    ul {
      font-weight: 600;
      margin-block: 1rem;
    }

    li {
      margin-left: 1.5rem;
    }
  }

  .logo {
    position: absolute;
    height: 5rem;
    right: 5rem;
    bottom: 5rem;
    font-family: 'Ephesis';
    font-weight: 800;
    font-size: 4.5em;
    color: var(--color-headline-secondary);
  }

  .input__area {
    padding: 6rem 5rem;
    width: 100%;
    background: var(--color-background-secondary);
    color: var(--color-headline-secondary);
    display: flex;
    flex-direction: column;
    justify-content: center;
    gap: 0.5rem;
  }

  /* MOBILE */
  @media screen and (max-width: 1200px) {
    .container {
      flex-direction: column-reverse;
    }

    .hero,
    .input__area {
      padding: 2.5rem;
      position: relative;
    }

    .logo {
      color: var(--color-headline);
    }
  }
</style>
