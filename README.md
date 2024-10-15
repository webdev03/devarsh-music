# devarsh-music

A barebones self-hosted music player!

It can use yt-dlp to download files from [supported sources](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md), and ffmpeg to convert the downloaded file into a standard format so that all web browsers can play the audio back.

Requires [bun](https://bun.sh/), [yt-dlp](https://github.com/yt-dlp/yt-dlp/), and [ffmpeg](https://ffmpeg.org/) to be installed on the machine.

## Starting

One command installs dependencies and starts the music player:

```bash
./start.sh
```

## Configuration

You can access the installation on port `3000` (to change this edit the `DEVARSH_MUSIC_PORT` environment variable). The default password is `InitialPassword`. You can change it by sending a `POST` HTTP request to `/api/password`, where the request body is the new password. All data is stored in `backend/music-data`.

If you have any ideas or need some help, please put them in the GitHub Issues tab on this repository and I can help you.
