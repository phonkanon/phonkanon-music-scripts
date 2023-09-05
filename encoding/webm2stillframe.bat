@echo off

rem webm2stillframe
rem convert a downloaded webm to a stillframe video
rem for example if you download a video from yt-dlp,
rem but you want to make the video a better encoded stillframe

rem allow for use with unicode
chcp 65001 > nul

rem some customizeable arguments
rem set resize_cover_art to "t" to resize the cover art
rem set cover_art_size to set your desired cover art size
rem tweak approxsize_offset_kb to better reflect actual output, if you'd like
rem I made it intentionally high (1200) just in case.
set "RESIZE_COVER_ART=t"
set "COVER_ART_SIZE=2048" :: Max 4chan video size is 2048x2048
set "FORMAT=WEBM" :: Set format to WEBM to create a webm, MP4 to create an mp4
set /a APPROXSIZE_OFFSET_KB=1200

setlocal enabledelayedexpansion

rem check for help flag
if /I "%~1" == "-help" (
    echo Hello! Welcome to webm2stillframe, a script for converting
    echo webm files to well-encoded stillimage webm files.
    echo To use the script, all you need to do is give a file as the
    echo first argument. If you wish to set a custom filename, then you can
    echo use the second arguement as the second argument.
    echo if you wish to delete the file after the conversion, pass -delete
    echo as the third argument.
    exit /b
)

rem print banner and stuff
echo  _       ____________  __  ___      ^| Covert WEBMs To Stillframes!
echo ^| ^|     / / ____/ __ )/  ^|/  /      ^| Developed by phonkanon
echo ^| ^| /^| / / __/ / __  / /^|_/ /       ^| https://github.com/phonkanon
echo ^| ^|/ ^|/ / /___/ /_/ / /  / /        ^| version 1.1
echo ^|__/^|__/_____/_____/_/  /_/         ^| 
echo             ^|__ ^\                   ^| 
echo             __/ /                   ^|
echo            / __/                    ^|
echo    _______/____/____    __          ^|
echo   / ___/_  __/  _/ /   / /          ^|
echo   ^\__ ^\ / /  / // /   / /           ^|
echo  ___/ // / _/ // /___/ /___         ^|
echo /____//_/_/___/_____/_____/_________^|
echo    / ____/ __ ^\/   ^|  /  ^|/  / ____/^| Constant Arguments
echo   / /_  / /_/ / /^| ^| / /^|_/ / __/   ^| Resize Cover Art: %RESIZE_COVER_ART%
echo  / __/ / _, _/ ___ ^|/ /  / / /___   ^| Cover Art Size: %COVER_ART_SIZE%
echo /_/   /_/ ^|_/_/  ^|_/_/  /_/_____/   ^| Output Format: %FORMAT%
echo                                     ^| Approx. Size Offset: %APPROX_OFFSET_KB%

rem set first argument to input file, second to the custom filename
set "input=%~1"
set "filename=%~2"

rem check if deletefile
set deletefile=no
if /I "%~3" == "-delete" (
    set deletefile=yes
)

rem extract the first frame of the video file
set "coverfilename=cover_%RANDOM%.jpg"
ffmpeg -loglevel panic -i "%input%" -vframes 1 -q:v 2 %coverfilename%
echo ^[WEBM2STILLFRAME^] Successfully Extracted Cover Art from webm

rem compress cover art
magick convert -quality 25 -strip %coverfilename% %coverfilename%
echo ^[IMGProcessor^] Successfully Compressed %coverfilename%

rem get the width for the cover art (assume it's a square)
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=width -of default^=nw^=1^:nk^=1 "%coverfilename%"') do set "coverwidth=%%A"

rem resize the cover art if necessary
if /I "%RESIZE_COVER_ART%" == "t" (
    if %coverwidth% gtr %COVER_ART_SIZE% (
        magick "%coverfilename%" -resize %COVER_ART_SIZE%x%COVER_ART_SIZE% "%coverfilename%"
        set "coverwidth=%COVER_ART_SIZE%"
        echo ^[IMGResizer^] Successfully Resized Cover Art to %COVER_ART_SIZE%x%COVER_ART_SIZE%
    )
)

rem get size of cover art
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format^=size -of default^=nw^=1^:nk^=1 "%coverfilename%"') do set "coversize=%%A"

rem get the pixel format of the cover art
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=pix_fmt -of default^=nw^=1^:nk^=1 "%coverfilename%"') do set "pix_fmt=%%A"

rem get duration of the video
for /f "tokens=*" %%A in ('ffprobe -loglevel error -select_streams a -show_entries stream^=duration -of default^=nw^=1^:nk^=1 "%input%"') do set "duration=%%A"

rem get filesize of the video
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format^=size -of default^=nw^=1^:nk^=1 "%input%"') do set "filesize=%%A"

rem now we want to extract the audio from the webm file
set "audiofilename=audio_%RANDOM%.opus"
ffmpeg -loglevel panic -stats -i "%input%" -c:a libopus "%audiofilename%"
echo ^[OPUSExtractor^] Successfully Extracted Audio From WEBM

rem get the bitrate of the audio file
for /f "tokens=*" %%A in ('ffprobe -loglevel error -select_streams a -show_entries format^=bit_rate -of default^=nw^=1^:nk^=1 "%audiofilename%"') do set "bit_rate=%%A"

rem calculate approximate filesize
set /a byterate=bit_rate/8
set /a audiorate=byterate*duration
set /a approxsize=audiorate+coversize
set /a approxsize=approxsize/1000
set /a approxsize=approxsize+APPROXSIZE_OFFSET_KB
set "approxsize=%approxsize% kb"

echo ----------FILE INFORMATION----------
echo Pixel Format: %pix_fmt%
echo Video Filesize In Bytes: %filesize%
echo -------------------------------------

rem now, depending on the format, we we now want to create a better encoded video.
if /I "%FORMAT%" == "WEBM" (
    rem print output stuff
    echo ----------OUTPUT INFORMATION----------
    echo Filename: %filename%.webm
    echo Cover Art Filename: %coverfilename%
    echo Filetype: webm
    echo Audio Codec: libopus
    echo Video Codec: libvpx-vp9
    echo Video Dimensions: %coverwidth%x%coverwidth%
    echo Approx. Video Size: %approxsize%
    echo --------------------------------------
    ffmpeg -loop 1 -framerate 1 -loglevel error -stats -i "%coverfilename%" -i "%audiofilename%" -c:a libopus -c:v libvpx-vp9 -crf 30 -cpu-used 5 -tile-columns 3 -threads 0 -shortest -strict -2 -vbr on -compression_level 10 "!filename!.webm"
    del %audiofilename%
    del %coverfilename%
    exit /b
)

if /I "%FORMAT%" == "MP4" (
    rem print output stuff
    echo ----------OUTPUT INFORMATION----------
    echo Filename: %filename%.mp4
    echo Cover Art Filename: %coverfilename%
    echo Filetype: mp4
    echo Audio Codec: libaac
    echo Video Codec: libx264
    echo Video Dimensions: %coverwidth%x%coverwidth%
    echo Approx. Video Size: %approxsize%
    echo --------------------------------------    
    ffmpeg -loop 1 -framerate 1 -loglevel error -stats -i "%coverfilename%" -i "%audiofilename%" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:a aac -c:v libx264 -crf 23 -threads 0 -shortest "!filename!.mp4"
    del %audiofilename%
    del %coverfilename%
    exit /b
)