<script lang="ts">
  let { children, dark = false, ...props } = $props();
</script>

<button class={`btn ${dark ? 'btn-dark' : ''}`} {...props}>
  {@render children?.()}
</button>

<style>
  .btn {
    font-weight: 650;
    background-color: var(--color-button);
    color: var(--color-button-text);
    font-size: var(--input-font-size);
    border-radius: var(--input-border-radius);
    padding: var(--input-padding);
    transition: all 900 ease-in-out;
  }

  .btn-dark {
    background-color: var(--color-background);
    color: var(--color-headline);
  }

  .btn:hover {
    opacity: 0.9;
    /* background-color: var(--color-complement-200); */
  }
</style>
