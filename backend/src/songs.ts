import { DATA_DIR } from "./data";
import * as path from "path";

import { readFile, readdir, exists } from "fs/promises";
import { randomBytes } from "crypto";

import { z } from "zod";

/**
 * Generates a song ID
 */
export async function generateId() {
  let id: string = randomBytes(12).toString("hex");
  while (await exists(path.join(DATA_DIR, "songs", id))) id = randomBytes(12).toString("hex");
  return id;
}

export const Metadata = z.object({
  title: z.string(),
  artist: z.string().optional(),
  album: z.string().optional(),
  year: z.number().optional(),
  url: z.string().url().optional()
});

export const songs = {
  getAllSongs: async () =>
    (
      await Promise.all(
        (await readdir(path.join(DATA_DIR, "songs"), { withFileTypes: true }))
          .filter((dirent) => dirent.isDirectory())
          .map((dirent) => dirent.name)
          .map(async (id) => {
            try {
              return {
                id,
                metadata: await Metadata.parseAsync(
                  JSON.parse(
                    (await readFile(path.join(DATA_DIR, "songs", id, "metadata.json"))).toString()
                  )
                )
              };
            } catch {
              return null;
            }
          })
      )
    ).filter(Boolean)
};
