import * as path from "path";
import { writeFile } from "fs/promises";

import { transcode } from "./ffmpeg";
import { generateId } from "./songs";
import { DATA_DIR } from "./data";

if (!Bun.which("yt-dlp")) {
  console.warn(
    "[WARN] yt-dlp was not found! Some features WILL NOT WORK without yt-dlp! Please read the README in the devarsh-music repository to learn how to fix this!"
  );
} else {
  const result = Bun.spawnSync({
    cmd: ["yt-dlp", "--version"],
  });
  
  if (result.success === false) {
    console.error("Command failed to execute!");
    console.error(new TextDecoder().decode(result.stderr)); // Log the error
  } else {
    console.log("Command executed successfully!");
    console.log(new TextDecoder().decode(result.stdout)); // Log the output
  }
}

/**
 * Using yt-dlp, download an audio file and add it to the songs list
 * @param url The URL to download from
 */
export async function download(url: string, title: string = url) {
  try {
    new URL(url);
  } catch {
    throw new Error("Invalid URL provided.");
  }
  const id = await generateId();

  const downloadProcess = Bun.spawn({
    cmd: ["yt-dlp", "-x", "-o", path.join(DATA_DIR, "songs", id, "audio.%(ext)s"), url],
    stdout: "inherit"
  });

  await downloadProcess.exited;

  await writeFile(
    path.join(DATA_DIR, "songs", id, "metadata.json"),
    JSON.stringify({
      title,
      year: new Date().getFullYear()
    })
  );

  await transcode(id);

  return id;
}
