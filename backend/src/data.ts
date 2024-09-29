import { readFile, writeFile, exists } from "fs/promises";
import * as path from "path";

export const DATA_DIR = process.env["MUSIC_DATA_DIR"] || "./music-data/";

export const password = {
  exists: () => exists(path.join(DATA_DIR, "password.txt")),
  check: async (attempt: string) => {
    const hash = (await readFile(path.join(DATA_DIR, "password.txt"))).toString();
    return await Bun.password.verify(attempt, hash);
  },
  set: async (value: string) => {
    await writeFile(path.join(DATA_DIR, "password.txt"), await Bun.password.hash(value));
  }
};
