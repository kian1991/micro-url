<script lang="ts">
  import Copy from '@tabler/icons-svelte/icons/copy';

  const { message, isError: errorProp = false, ...props } = $props();
  let isError = $state(errorProp);
  let isSuccess = $state(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(message);
      isSuccess = true;

      // remove success message after 2 secs
      setTimeout(() => {
        isSuccess = false;
      }, 2000);
    } catch (err) {
      isError = true;
      console.error('Copy failed', err);
    }
  };
</script>

<button
  type="button"
  class="message"
  class:is-error={isError}
  class:is-success={isSuccess}
  onclick={() => handleCopy()}
  {...props}
>
  <span title="Click to copy.">
    {#if isSuccess}
      Copied.
    {:else}
      {message} <Copy size={16} style="display: inline;" />
    {/if}
  </span>
</button>

<style>
  .message {
    background-color: var(--color-tag-text);
    color: var(--color-tag-bg);
    border-radius: var(--input-border-radius);
    width: 250px;
    height: 2rem;
    margin-inline: auto;
    transition: color 200ms ease-in-out;
    font-family: monospace;

    span {
      display: flex;
      align-items: center;
      justify-content: center;
      font: bold;
      user-select: none;
      gap: 0.5rem;
    }
  }

  .message:hover {
    cursor: pointer;
    opacity: 0.8;
  }

  .is-error {
    background-color: #c77c6f;
    color: #3d2723;
  }

  .is-success {
    background-color: #abdfa2;
    color: #364633;
    font-family: inherit;
  }
</style>
