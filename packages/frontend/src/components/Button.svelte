<script lang="ts">
  let { children, dark = false, ...props } = $props();
</script>

<button class={`${dark ? 'btn-dark' : ''}`} {...props}>
  {@render children?.()}
</button>

<style>
  button {
    font-weight: 650;
    background-color: var(--color-button);
    color: var(--color-button-text);
    font-size: var(--input-font-size);
    border-radius: var(--input-border-radius);
    padding: var(--input-padding);
    transition: all 900 ease-in-out;

    &:hover {
      filter: contrast(1.1);
      box-shadow: 1px 1px 2px rgba(0, 0, 0, 0.1);
    }

    &:disabled {
      opacity: 0.4;
      pointer-events: none;
    }
  }

  .btn-dark {
    background-color: var(--color-background);
    color: var(--color-headline);
  }
</style>
