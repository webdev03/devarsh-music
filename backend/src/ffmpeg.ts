import * as path from "path";
import { rename, rm } from "fs/promises";

import { DATA_DIR } from "./data";

if (!Bun.which("ffmpeg")) {
  console.warn(
    "[WARN] ffmpeg was not found! Some features WILL NOT WORK without ffmpeg! Please read the README in the devarsh-music repository to learn how to fix this!"
  );
} else if (
  Bun.spawnSync({
    cmd: ["ffmpeg", "--version"]
  }).success === false
) {
  console.warn(
    "[WARN] We tested your installation for ffmpeg, and while ffmpeg was found, it did not start properly! Some features WILL NOT WORK without ffmpeg! Please ask for support!!!"
  );
}

/**
 * Transcodes an audio file
 * https://developer.mozilla.org/en-US/docs/Web/Media/Formats/Audio_codecs#example_music_for_streaming may be useful
 * @param id The ID of the song
 */
export async function transcode(id: string) {
  const glob = new Bun.Glob(path.join(DATA_DIR, "songs", id, "audio.*"));
  const file = (await Array.fromAsync(glob.scan()))[0];
  await rename(file, file + ".tmp");

  const process = Bun.spawn({
    cmd: ["ffmpeg", "-i", file + ".tmp", "-c:a", "aac", "-b:a", "128k", path.join(DATA_DIR, "songs", id, "audio.mp4")],
    stdout: "inherit"
  });

  await process.exited;

  await rm(file + ".tmp");
}
