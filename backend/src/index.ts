const startTime = Date.now();

import { DATA_DIR, password } from "./data";
import { songs } from "./songs";
import { download } from "./yt-dlp";
import { transcode } from "./ffmpeg";

import { Hono } from "hono";
import { serveStatic } from "hono/bun";
import { basicAuth } from "hono/basic-auth";

import { exists, mkdir, rm } from "fs/promises";
import * as path from "path";
import { Glob } from "bun";

if (!(await exists(DATA_DIR))) await mkdir(DATA_DIR);
if (!(await password.exists())) await password.set("InitialPassword");

const app = new Hono();

app.use(
  basicAuth({
    verifyUser: (_username, passwordAttempt, _c) => password.check(passwordAttempt)
  })
);

app.get("/api/hello", (c) => c.text("Hiii! :D"));

app.get("/api/songs", async (c) => {
  return c.json(await songs.getAllSongs());
});

app.get("/api/playback/:id", async (c) => {
  const songId = c.req.param("id");
  const filePath = Array.from(
    new Glob(path.join(DATA_DIR, "songs", songId, "audio.*")).scanSync()
  )[0];

  if (!filePath) return c.text("File not found", 404);

  const audioFile = Bun.file(filePath);

  try {
    // This stream allows for the client to start playing the audio before receiving the full file
    const stream = new ReadableStream({
      async pull(controller) {
        const reader = audioFile.stream().getReader();
        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            controller.enqueue(value);
          }
          controller.close();
        } catch (error) {
          controller.error(error);
        }
      }
    });

    return new Response(stream, {
      headers: {
        "Content-Type": audioFile.type,
        "Content-Disposition": `inline; filename="${path.basename(filePath)}"`
      }
    });
  } catch (err) {
    console.error(err);
    return c.text("Error while streaming the file", 500);
  }
});

app.post("/api/transcode/:id", async (c) => {
  const songId = c.req.param("id");
  if (!songId || songId.includes("/") || songId.length < 3) return c.text("Invalid ID", 400);
  await transcode(songId);
  return c.text("Transcoded");
});

app.delete("/api/songs/:id", async (c) => {
  const songId = c.req.param("id");
  if (!songId || songId.includes("/") || songId.length < 3) return c.text("Invalid ID", 400);
  await rm(path.join(DATA_DIR, "songs", songId), {
    recursive: true
  });
  return c.text("Deleted");
});

app.post("/api/yt-dlp", async (c) => {
  const url = c.req.query("url");
  if (!url) return c.text("No URL!", 400);
  const result = await download(url, c.req.query("title"));
  return c.json({
    id: result
  });
});

app.post("/api/password", async (c) => {
  const newPassword = (await c.req.text()).trim();
  if(newPassword.length < 1) return c.text("Password cannot be empty", 400);
  await password.set(newPassword);
  return c.text("Done!");
});

app.get("/api/health", (c) =>
  c.json({
    uptime: Number(((Date.now() - startTime) / 1000).toFixed(2))
  })
);

app.get("/about", (c) => c.text("Devarsh's Music Player. Thanks for using my software!"));

app.use(
  serveStatic({
    root: "../frontend/dist"
  })
);

export default app;
