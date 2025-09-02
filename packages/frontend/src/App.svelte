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

      <h1 class="header">
        M<span style="font-size: .8em; font-weight:400">icro</span> URL
      </h1>
      <p>
        Big links are like that one friend who tells a five-minute story in
        twenty — nobody’s got time for that. Micro URL takes your endless, ugly
        links and transforms them into sleek, memorable shortcuts that are easy
        to share anywhere. Whether you’re sending a client a polished document
        link, sharing an invite on social media, or just trying to keep things
        neat, Micro URL makes it quick, effortless, and professional. Your links
        get shorter, your life gets easier, and your click-throughs get better.
      </p>
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

  p {
    color: var(--color-paragraph);
  }

  .hero {
    width: 100%;
    padding: 6rem 5rem;
    min-height: 100vh;
    background: var(--gradient);
  }

  .logo {
    position: absolute;
    height: 5rem;
    right: 5rem;
    bottom: 5rem;
    font-family: 'Ephesis';
    font-weight: 800;
    font-size: 4.5em;
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
