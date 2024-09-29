<script lang="ts">
  import "bootstrap";
  import "bootstrap-icons/font/bootstrap-icons.css";
  import { onMount } from "svelte";
  import toast, { Toaster } from "svelte-french-toast";

  interface Song {
    id: string;
    metadata: {
      title: string;
      artist?: string;
      album?: string;
      year?: number;
      url?: string;
    };
  }

  let songs: Song[] = [];

  $: currentSong = songs.find((x) => audioPlayer.src.endsWith(x.id));

  async function getSongs() {
    songs = await (await fetch("/api/songs")).json();
  }
  getSongs();
  setInterval(getSongs, 10000);

  let audioPlayer: HTMLAudioElement;

  function playSong(id: string) {
    audioPlayer.src = `/api/playback/${id}`;
    audioPlayer.currentTime = 0;
    audioPlayer.play();
  }

  let playbackMode: "repeat" | "shuffle" | "continuous" = "continuous";

  function switchPlaybackMode() {
    if (playbackMode === "repeat") playbackMode = "shuffle";
    else if (playbackMode === "shuffle") playbackMode = "continuous";
    else playbackMode = "repeat";
  }

  onMount(() => {
    audioPlayer.addEventListener("ended", () => {
      if (playbackMode === "repeat") {
        audioPlayer.currentTime = 0;
        audioPlayer.play();
      } else if (playbackMode === "shuffle") {
        const newSong = songs[Math.floor(Math.random() * songs.length)];
        playSong(newSong.id);
      } else if (playbackMode === "continuous") {
        const currentIdx = songs.findIndex((x) => audioPlayer.src.endsWith(x.id));
        const newSong = songs[(currentIdx + 1) % songs.length];
        playSong(newSong.id);
      }
    });
  });

  function secondsToFormatted(seconds: number) {
    return `${Math.floor(seconds / 60)}:${(Math.floor(seconds) % 60).toString().padStart(2, "0")}`;
  }

  let currentTime = "";
  setInterval(() => {
    currentTime = `${secondsToFormatted(audioPlayer.currentTime)} / ${isNaN(audioPlayer.duration) || audioPlayer.duration == Infinity ? "?:??" : secondsToFormatted(audioPlayer.duration)}`;
  }, 100);

  let downloadURL = "";
  let downloadTitle = "";
</script>

<Toaster />

<nav class="navbar navbar-expand-lg bg-body-tertiary">
  <div class="container-fluid">
    <a class="navbar-brand" href="/">Music!</a>
    <button
      class="navbar-toggler"
      type="button"
      data-bs-toggle="collapse"
      data-bs-target="#navbarNav"
      aria-controls="navbarNav"
      aria-expanded="false"
      aria-label="Toggle navigation"
    >
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav">
        <li class="nav-item">
          <a class="nav-link" href="/about">About</a>
        </li>
        <li>
          <button data-bs-toggle="modal" data-bs-target="#downloadModal" class="nav-link"
            ><i class="bi bi-download"></i> Download</button
          >
        </li>
      </ul>
    </div>
  </div>
</nav>
<div
  class="flex-shrink-1 flex-basis-auto list-group list-group-flush h-full flex-grow-1 overflow-scroll"
>
  {#each songs as song}
    <button
      on:click={() => playSong(song.id)}
      class="list-group-item list-group-item-action d-flex justify-content-between align-items-center w-100"
      class:active={audioPlayer.src.endsWith(song.id)}
      aria-current={audioPlayer.src.endsWith(song.id)}
    >
      <span class="fw-bold">{song.metadata.title}</span>
      <div style="float: left;">
        <button
          class="btn btn-outline-danger"
          on:click={async (e) => {
            e.stopPropagation();
            if (!confirm("Are you sure you want to delete " + song.metadata.title + "?")) return;
            console.log(song);
            toast.promise(
              fetch(`/api/songs/${song.id}`, {
                method: "DELETE"
              }).then((response) => {
                if (!response.ok) {
                  throw new Error();
                }
                getSongs();
                return response;
              }),
              {
                loading: "Deleting...",
                success: "Deleted!",
                error: "An error occurred while deleting!"
              }
            );
          }}><i class="bi bi-trash"></i></button
        >
      </div>
    </button>
  {/each}
</div>

{#if currentSong}
  <div class="w-100 d-flex justify-content-center float-end flex-grow-0 flex-shrink-1">
    <div class="border w-100 rounded p-4 m-2">
      <span class="fw-bold">{currentSong.metadata.title}</span>
      <button
        title={playbackMode.charAt(0).toUpperCase() + playbackMode.substring(1).toLowerCase()}
        class="ms-2 btn btn-outline-success"
        on:click={switchPlaybackMode}
      >
        {#if playbackMode === "shuffle"}
          <i class="bi bi-shuffle"></i>
        {:else if playbackMode === "continuous"}
          <i class="bi bi-arrow-return-right"></i>
        {:else if playbackMode === "repeat"}
          <i class="bi bi-repeat"></i>
        {/if}
      </button>
      <br />
      <span>{currentTime}</span>
      <br />
      <div class="mt-2 d-flex align-items-center">
        <button
          on:click={() => {
            if (audioPlayer.paused) audioPlayer.play();
            else audioPlayer.pause();

            audioPlayer = audioPlayer;
          }}
          class="btn btn-primary me-4"
          ><i class={`bi ${audioPlayer.paused ? "bi-play-fill" : "bi-pause-fill"}`}></i></button
        >
        <input
          type="range"
          class="form-range"
          min="0"
          max={audioPlayer.duration}
          bind:value={audioPlayer.currentTime}
        />
      </div>
    </div>
  </div>
{/if}

<audio
  bind:this={audioPlayer}
  on:timeupdate={() => (audioPlayer = audioPlayer)}
  on:durationchange={() => (audioPlayer = audioPlayer)}
  hidden
/>

<!-- Download Modal -->
<div
  class="modal fade"
  id="downloadModal"
  tabindex="-1"
  aria-labelledby="downloadModalLabel"
  aria-hidden="true"
>
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h1 class="modal-title fs-5" id="downloadModalLabel">Download with YT-DLP</h1>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <form>
          <div class="mb-3">
            <label for="download-url" class="col-form-label">URL:</label>
            <input
              type="url"
              class="form-control"
              id="download-url"
              placeholder="https://www.youtube.com/watch?v=-ZxPhDC-r3w"
              required
              bind:value={downloadURL}
            />
          </div>
          <div class="mb-3">
            <label for="download-title" class="col-form-label">Title:</label>
            <input
              type="url"
              class="form-control"
              id="download-title"
              placeholder="Intrinsic Gravity"
              bind:value={downloadTitle}
            />
          </div>
          <div class="alert alert-warning" role="alert">Only audio will be downloaded!</div>
        </form>
      </div>
      <div class="modal-footer">
        <button
          type="button"
          class="btn btn-primary"
          on:click={async () => {
            if (!downloadURL) {
              alert("No URL provided");
              return;
            }
            toast.promise(
              fetch(
                "/api/yt-dlp?" +
                  new URLSearchParams({
                    url: downloadURL,
                    title: downloadTitle
                  }),
                {
                  method: "POST"
                }
              ).then((response) => {
                if (!response.ok) {
                  throw new Error();
                }
                getSongs();
                return response;
              }),
              {
                loading: "Downloading...",
                success: "Downloaded!",
                error: "An error occurred while downloading!"
              }
            );
          }}>Download</button
        >
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>
