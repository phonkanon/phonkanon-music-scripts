// ==UserScript==
// @name         Soundcloud Full-Size Cover Art Downloader
// @namespace    http://tampermonkey.net/
// @version      0.4
// @description  Add a download button to Soundcloud tracks to download the full-size cover art
// @author       phonkanon
// @match        https://soundcloud.com/*
// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// ==/UserScript==

(function() {
    'use strict';

    GM_addStyle(`
        #fullSizeCoverDownloadBtn {
            display: inline-block;
            padding: 5px 15px;
            color: #fff;
            background-color: #ff5500;
            border: none;
            border-radius: 5px;
            font-weight: bold;
            cursor: pointer;
            margin-top: 10px;
            text-decoration: none;
            text-align: center;
        }
        #fullSizeCoverDownloadBtn:hover {
            background-color: #ff7733;
        }
    `);

    function downloadImage(url, filename) {
        GM_xmlhttpRequest({
            method: "GET",
            url: url,
            responseType: "blob",
            onload: function(response) {
                const blob = new Blob([response.response], {type: "image/jpeg"});
                const downloadUrl = URL.createObjectURL(blob);
                const a = document.createElement("a");
                document.body.appendChild(a);
                a.style = "display: none";
                a.href = downloadUrl;
                a.download = filename + "-cover.jpg";
                a.click();
                URL.revokeObjectURL(downloadUrl);
            }
        });
    }

    function addDownloadButton() {
        // Check if the button is already added
        if (document.getElementById('fullSizeCoverDownloadBtn')) {
            return;
        }

        // Try to find the artwork from both potential locations
        let artworkSpan = document.querySelector('.listenArtworkWrapper__artwork span.sc-artwork');
        if (!artworkSpan) {
            artworkSpan = document.querySelector('.listenInfo span.sc-artwork');
        }

        if (!artworkSpan) return;

        // Extract the cover art URL and modify it to point to the original size
        const backgroundImageStyle = artworkSpan.style.backgroundImage;
        const artworkUrl = backgroundImageStyle.match(/url\("(.+)-t\d+x\d+\.jpg"\)/);
        if (!artworkUrl || artworkUrl.length < 2) return;

        const originalCoverUrl = artworkUrl[1] + '-original.jpg';

        // Get the song title
        const titleElem = document.querySelector('.soundTitle__title > span');
        let songTitle = titleElem ? titleElem.innerText.trim() : "soundcloud";
        songTitle = songTitle.replace(/[^a-z0-9\-_]+/gi, '_');  // clean up the title for filename usage

        // Create the download button
        const downloadButton = document.createElement('a');
        downloadButton.href = "#";
        downloadButton.innerText = 'Download Full Size Cover';
        downloadButton.id = 'fullSizeCoverDownloadBtn';

        // Event listener to trigger the download
        downloadButton.addEventListener('click', (e) => {
            e.stopPropagation();
            e.preventDefault();
            downloadImage(originalCoverUrl, songTitle);
        });

        // Find the track/playlist title container and append the download button below it
        const titleContainer = document.querySelector('.soundTitle__titleContainer');
        if (titleContainer) {
            titleContainer.parentNode.insertBefore(downloadButton, titleContainer.nextSibling);
        }
    }

    // Initially try to add the button
    addDownloadButton();

    // Listen for page changes since Soundcloud is a single-page app
    new MutationObserver(addDownloadButton).observe(document.body, {
        childList: true,
        subtree: true
    });
})();
