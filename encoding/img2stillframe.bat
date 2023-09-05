@echo off

rem img2stillframe
rem combine audio and an image into a single video
rem for example if you hated the cover of a certain song and
rem wanted to use a different cover, this will do that for you

rem allow for use with unicode
chcp 65001 > nul

rem some customizeable arguments
rem set resize_cover_art to "t" to resize the cover art
rem set cover_art_size to your desired cover art width
rem unlike the other scripts, you can use rectangular images if you'd like
rem the program will retain the aspect ratio of the cover art
rem set the video format to webm or mp4, whichever one you'd prefer
rem tweak approxsize_offset_kb to better reflect actual output, if you'd like
rem I made it intentionally high (1200) just in case
set "RESIZE_COVER_ART=t"
set "COVER_ART_SIZE=2048" :: Max 4chan video size is 2048x2048
set "FORMAT=WEBM"
set /a APPROX_OFFSET_KB=1200

setlocal enabledelayedexpansion

rem check for help flag
if /I "%~1" == "-help" (
    echo Hello! Welcome to img2stillframe, a script for combining
    echo images and audio into a single video file
    echo To use the script, provide it with three arguments:
    echo 1. Your Audio File
    echo 2. Your Cover Art File
    echo 3. The Filename
    echo That's it! After you've supplied the three arguments
    echo in that order, you're good to go! 
    echo If you'd like to customize the functionality of the script,
    echo you can edit the values at the top of the script to better
    echo accomodate your needs.
    exit /b
)

rem print banner and stuff
echo        ______  ________        ^| Combine images with audio!
echo        /  _/  ^|/  / ___/       ^| Developed by phonkanon
echo       _/ // /^|_/ / (_ /        ^| https://github.com/phonkanon
echo      /___/_/_ /_/^\___/         ^| version 1.0
echo            ^|_  ^|               ^|
echo           / __/                ^|
echo    ____ _/____/____   __       ^|
echo   / __/_  __/  _/ /  / /       ^|
echo  _^\ ^\  / / _/ // /__/ /__      ^| Constant Arguments
echo /___/_/_/_/___/____/____/____  ^| Resize Cover Art: %RESIZE_COVER_ART%
echo   / __/ _ ^\/ _ ^| /  ^|/  / __/  ^| Cover Art W/H Limit: %COVER_ART_SIZE%
echo  / _// , _/ __ ^|/ /^|_/ / _/    ^| Output Format: %FORMAT%
echo /_/ /_/^|_/_/ ^|_/_/  /_/___/    ^| Approx. Size Offset: %APPROX_OFFSET_KB%

rem set first argument to the audio, second to image, third to filename
set "audiofile=%~1"
set "imagefile=%~2"
set "filename=%~3"

rem compress the cover art a little bit to reduce filesize
rem create a new file for the cover art in case its important
set "imagefilename=%~n1"
set "coverartfile=%imagefilename%_compressed.jpg"
magick convert -quality 25 -strip "%imagefile%" "%coverartfile%"
echo ^[IMGProcessor^] Successfully Compressed %imagefile%

rem get the height and width of the cover art
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=width -of default^=nw^=1^:nk^=1 "%coverartfile%"') do set "coverwidth=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=height -of default^=nw^=1^:nk^=1 "%coverartfile%"') do set "coverheight=%%A"

rem resize that cover art if we need to
if /I "%RESIZE_COVER_ART%" == "t" (
    rem create a checkvar to check if cover art is bigger than size constraint
    set "_checkvar_="
    if "%coverwidth%" gtr "%COVER_ART_SIZE%" set "_checkvar_=1"
    if "%coverheight%" gtr "%COVER_ART_SIZE%" set "_checkvar_=1"
    if "%_checkvar_%" equ 1 (
        magick "%coverartfile%" -resize %COVER_ART_SIZE%x%COVER_ART_SIZE% "%coverartfile%"
        rem get the dimensions again now that we've resized the art
        for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=width -of default^=nw^=1^:nk^=1 "%coverartfile%"') do set "coverwidth=%%A"
        for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=height -of default^=nw^=1^:nk^=1 "%coverartfile%"') do set "coverheight=%%A"
        rem now tell the user about it
        echo ^[IMGResizer^] Successfully Resized Cover Art to %coverwidth%x%coverheight%
    )
)

rem get the filesize of the cover art
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format^=size -of default^=nw^=1^:nk^=1 "%coverartfile%"') do set "coversize=%%A"

rem get the pixel format of the cover art
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=pix_fmt -of default^=nw^=1^:nk^=1 "%coverartfile%"') do set "pix_fmt=%%A"

rem get the duration of the audio file
for /f "tokens=*" %%A in ('ffprobe -loglevel error -select_streams a -show_entries stream^=duration -of default^=nw^=1^:nk^=1 "%audiofile%"') do set "duration=%%A"

rem get the bitrate of the audio file
for /f "tokens=*" %%A in ('ffprobe -loglevel error -select_streams a -show_entries format^=bit_rate -of default^=nw^=1^:nk^=1 "%audiofile%"') do set "bit_rate=%%A"

rem calculate the approximate filesize
set /a byterate=bit_rate/8
set /a audiorate=byterate*duration
set /a approxsize=audiorate+coversize
set /a approxsize=approxsize/1000
set /a approxsize=approxsize+APPROXSIZE_OFFSET_KB
set "approxsize=%approxsize% kb"

rem print file information
echo ----------FILE INFORMATION----------
echo ^[COVER^] Pixel Format: %pix_fmt%
echo ^[COVER^] Filesize in bytes: %coversize%
echo ^[AUDIO^] Duration: %duration%
echo ^[AUDIO^] Bit Rate: %bit_rate%
echo ------------------------------------

rem print filename and stuff to the console
echo ^[IMG2STILLFRAME] Now Combining %input% and %coverartfile%, saving to %filename%.%FORMAT%

if /I "%FORMAT%" == "WEBM" (
    rem print output and stuff
    echo ----------OUTPUT INFORMATION----------
    echo Filename: %filename%.webm
    echo Cover Art Filename: %coverartfile%
    echo Filetype: webm
    echo Audio Codec: libopus
    echo Video Codec: libvpx-vp9
    echo Video Dimensions: %coverwidth%x%coverheight%
    echo Approx. Video Size: %approxsize%
    echo --------------------------------------
    ffmpeg -loop 1 -framerate 1 -loglevel error -stats -i "%coverartfile%" -i "%audiofile%" -c:a libopus -c:v libvpx-vp9 -crf 30 -cpu-used 5 -tile-columns 3 -threads 0 -shortest -strict 2 -vbr on -compression_level 10 "!filename!.webm"
    rem clean up
    del "%coverartfile%"
    exit /b
)

if /I "%FORMAT%" == "MP4" (
    rem print output and stuff
    echo ----------OUTPUT INFORMATION----------
    echo Filename: %filename%.%FORMAT%
    echo Cover Art Filename: %coverartfile%
    echo Filetype: %FORMAT%
    echo Audio Codec: libaac
    echo Video Codec: libx264
    echo Video Dimensions: %coverwidth%x%coverheight%
    echo Approx. Video Size: %approxsize%
    echo --------------------------------------
    ffmpeg -loop 1 -framerate 1 -loglevel error -stats -i "%coverartfile%" -i "%audiofile%" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:a aac -c:v libx264 -crf 23 -threads 0 -t %duration% "!filename!.mp4"
    rem clean up
    del "%coverartfile%"
    exit /b  
)