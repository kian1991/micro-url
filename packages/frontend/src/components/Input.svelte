<script lang="ts">
  let { value = $bindable(), ...props } = $props();
</script>

<input class="input" bind:value {...props} />

<style>
  .input {
    /* border: 2px solid var(--color-background); */
    background-color: var(--color-input-bg);
    color: var(--color-headline-secondary);
    font-size: var(--input-font-size);
    border-radius: var(--input-border-radius);
    padding: var(--input-padding);
  }

  .input:focus {
    outline: 2px solid var(--color-headline);
  }

  .input:user-invalid {
    outline: 2px solid var(--color-highlight);
  }
</style>
