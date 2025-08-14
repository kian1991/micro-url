<script lang="ts">
  import { onMount } from 'svelte';
  import Input from './components/Input.svelte';
  import Button from './components/Button.svelte';
  import Logo from './assets/murl.png';

  let apiKey = $state('');
  let droppedUrl = $state('');
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
</script>

<main class="main">
  <span class="logo">xoxo Murl</span>
  <div class="container">
    <div class="hero">
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
    <div class="input__area">
      <h1>Drop-In</h1>
      <Input
        type="text"
        placeholder="https://pretty-long.url/that/loves/to/be/shrinked"
        bind:value={droppedUrl}
      />
      {#if AUTH_ENABLED}
        <Input type="text" placeholder="Enter API Key." bind:value={apiKey} />
      {/if}
      <Button onclick={() => alert('clicked')}>SHORTEN</Button>
    </div>
    <!-- <div style="margin-top: 2rem;">
      <span class="badge">
        <Button
          aria-label="copy button"
          style="display: flex; gap: 1rem; align-items: center"
        >
          <span>https://localhost:3000/aG32Jx</span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            style="display: inline;"
            stroke="currentColor"
            stroke-width="3"
            stroke-linecap="round"
            stroke-linejoin="round"
            ><rect width="8" height="4" x="8" y="2" rx="1" ry="1"></rect><path
              d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"
            ></path></svg
          ></Button
        >
      </span>
    </div> -->
  </div>
</main>

<style>
  .badge {
    font-family: monospace;
    font-size: 1.4em;
    font-weight: 600;
    display: flex;
    align-items: center;
    gap: 1rem;
    padding: 1.25rem 1.5rem;
    border-radius: var(--input-border-radius);
  }

  .highlight {
    /* color: var(--color-highlight); */
  }

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
    }

    .logo {
      color: var(--color-headline);
    }
  }
</style>
