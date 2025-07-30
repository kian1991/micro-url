import { SLUG_SEQUENCE } from '../constants';

/**
 * Creates a deterministic mock for `randomBytes`, cycling through a predefined sequence of byte arrays.
 * Useful for testing scenarios like slug generation where collisions should be simulated.
 *
 * @param sequence - An array of byte arrays to be returned one by one on each call to `randomBytes`.
 * @returns An object with a `randomBytes` function that returns the next buffer in the sequence.
 */
export function createRandomBytesMock(sequence = SLUG_SEQUENCE) {
  let i = 0;
  return {
    randomBytes: () => {
      if (i >= sequence.length) {
        throw new Error(`randomBytesMock: sequence exhausted at index ${i}`);
      }
      return Buffer.from(sequence[i++].bytes);
    },
  };
}
