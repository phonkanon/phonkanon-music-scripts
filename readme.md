# Phonkanon's music scripts

This repository contains a collection of scripts to make media file manipulation and conversion easier. These scripts are tailored and optimized for creating stillframe videos. Below is a quick guide to each of the scripts available.

**NOTE**: To use these scripts, you must first install [imagemagick](https://imagemagick.org/script/download.php) and [ffmpeg](https://ffmpeg.org/download.html).

## Table of Contents

- [Phonkanon's music scripts](#phonkanons-music-scripts)
  - [Table of Contents](#table-of-contents)
    - [img2stillframe.bat](#img2stillframebat)
    - [mp32mp4.bat](#mp32mp4bat)
    - [mp32webm.bat](#mp32webmbat)
    - [webm2stillframe.bat](#webm2stillframebat)
    - [soundcloud-cover-dl](#soundcloud-cover-dl)
  - [Contributing](#contributing)

---

### img2stillframe.bat

This script is designed for combining images and audio into a single video file.

**Usage:**

```bash
img2stillframe.bat [Audio File] [Cover Art File] [Filename]
```

**Flags:**

- `-help`: Displays the usage guide.

**Note:** You can edit the values at the top of the script for further customization.

---

### mp32mp4.bat

Convert MP3 files to MP4 format easily with this script.

**Usage:**

```bash
mp32mp4.bat [MP3 File] [Format] [-delete (optional)]
```

**Flags:**

- `-help`: Displays the usage guide.
  
**Format Options:**

- `{title}`: The title of the song.
- `{artist}`: The artist of the song.
- `{album}`: The album of the song.

**Note:** Edit the script directly for more customization.

---

### mp32webm.bat

Convert your MP3 files to the webm format.

**Usage:**

```bash
mp32webm.bat [MP3 File] [Format] [-delete (optional)]
```

**Flags:**

- `-help`: Displays the usage guide.
  
**Format Options:**

- `{title}`: The title of the song.
- `{artist}`: The artist of the song.
- `{album}`: The album of the song.

**Note:** For more customization, feel free to edit the script directly.

---

### webm2stillframe.bat

Convert webm files to a well-encoded still image webm format.

**Usage:**

```bash
webm2stillframe.bat [Webm File] [Custom Filename (optional)] [-delete (optional)]
```

**Flags:**

- `-help`: Displays the usage guide.


**Note:** Once again, feel free to edit the script as you please.

---

### soundcloud-cover-dl

This userscript allows you to download the full-sized cover art from Soundcloud tracks. To use, install a userscript manager like Tampermonkey and add the script. A button will appear on Soundcloud tracks, allowing for quick and easy cover art downloads.

This is useful because when you download tracks using yt-dlp, the cover isn't embedded by default, so you can use this userscript to download it.

**Usage:**

- Navigate to a Soundcloud track.
- Click the "Download Full Size Cover" button.


**Note:** As always, feel free to edit the script directly.

---

### soundcloud-copy-metadata

Meant to be used in tandem with the previous userscript. This userscript gives you a button that extracts metadata from the webpage and copies it to your clipboard as an ffmpeg command. This way, when you download from yt-dlp, you can create a new MP3 file that embeds all the metadata and album art all in one go.

---

## Contributing

Feel free to fork, star, and contribute to this repository. All contributions are welcome and encouraged!

---
