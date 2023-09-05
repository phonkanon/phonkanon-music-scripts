// ==UserScript==
// @name         SoundCloud Metadata to FFmpeg Command
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  Construct an FFmpeg command from SoundCloud song metadata.
// @author       phonkanon
// @match        https://soundcloud.com/*
// @grant        GM_addStyle
// ==/UserScript==

(function() {
    'use strict';

    // Add some styles to make the button look good
    GM_addStyle(`
        #copyFFmpegCmdBtn {
            background-color: #f50;
            color: white;
            border: none;
            border-radius: 4px;
            padding: 5px 10px;
            cursor: pointer;
            margin-left: 10px;
            transition: background-color 0.3s;
        }

        #copyFFmpegCmdBtn:hover {
            background-color: #e04000;
        }

        #copyFFmpegCmdBtn.copied {
            background-color: #4CAF50;
        }
    `);

    function createFFmpegCommand() {
        if (document.getElementById('copyFFmpegCmdBtn')) {
            return;
        }

        // Extract Metadata
        let title = document.querySelector('.soundTitle__title span').textContent.replace(/[\n\r]|\s{2,}/g,'');
        let artist = document.querySelector('.soundTitle__usernameHeroContainer a').textContent.replace(/[\n\r]|\s{2,}/g,'');
        let trackIDContent = document.querySelector('meta[property="twitter:app:url:googleplay"]').content;
        let trackURL = document.querySelector('meta[property="twitter:url"]').content;
        let trackID = trackIDContent.substring(trackIDContent.lastIndexOf(":") + 1);

        // Format filenames
        let titleFormatted = title.toLowerCase().replace(/[^a-z0-9\-_]+/gi, '_');
        let mp3Filename = `${title.replace(/\//g, '⧸')} [${trackID}].mp3`;
        let coverFilename = `${titleFormatted}-cover.jpg`;

        // Construct FFmpeg Command
        let ffmpegCmd = `ffmpeg -loglevel panic -stats -i "${mp3Filename}" -i "${coverFilename}" -codec copy -map 0 -map 1 -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" -metadata artist="${artist}" -metadata title="${title}" -metadata album="${artist} - ${title}" "${artist} - ${title.replace(/\//g, '⧸')}.mp3"`;

        // Create Button
        let btn = document.createElement("button");
        btn.id = "copyFFmpegCmdBtn";
        btn.textContent = "Copy Meta CMD";

        // Attach Event to Button
        btn.addEventListener("click", function() {
            navigator.clipboard.writeText(ffmpegCmd).then(function() {
                btn.textContent = 'Copied!';
                btn.classList.add('copied');
            }).catch(function(err) {
                console.error('Could not copy Meta command: ', err);
            });
        });

        // Insert Button next to the title
        let titleContainer = document.querySelector('.soundTitle__titleHeroContainer');
        titleContainer.appendChild(btn);
    }

    // Listen for page changes since Soundcloud is a single-page app
    new MutationObserver(createFFmpegCommand).observe(document.body, {
        childList: true,
        subtree: true
    });
})();
