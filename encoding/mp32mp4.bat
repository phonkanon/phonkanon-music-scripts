@echo off

rem allow for use with unicode
chp 65001 > null

rem some customizable arguments
rem set resize_cover_art to "t" to resize cover art
rem set cover_art_size to your desired size
rem tweak approximate_offset_kb to better reflect
rem the actual output if you'd like.
rem I made it intentionally high just in case
set "RESIZE_COVER_ART=f"
set "COVER_ART_SIZE=1200"
:: Various Filesizes
:: 4chan (webm) -> 2048 x 2048
:: Discord (mp4) -> No Limit (?)
set /a APPROXSIZE_OFFSET_KB=1200

setlocal enabledelayedexpansion

rem check for the help flag
if /I "%~1" == "-help" (
    echo Hello and Welcome to MP32MP4, a script for converting MP3 files to MP4 files.
    echo The first argument should be the mp3 file you wish to convert. You do not need
    echo to add any additional arguments if you'd like. You can just let the script do
    echo its thing. However, the additional arguments will give you more customization.
    echo:  
    echo The second argument is the format. This allows you to take advantage of the mp3
    echo file's built-in metadata. Here are the options that are at your disposal:
    echo {title} - The title of the song
    echo {artist} - The artist of the song
    echo {album} - The song's album
    echo Here's an example format: {title}-{artist}
    echo If the song's title was "This Feeling" and the artist was "my^!lane", the output
    echo file would be named "This Feeling-my^!lane.mp4"
    echo:
    echo Third argument is optional; pass -delete to delete the input file after processing.
    echo:   
    echo Make sure to tweak the values at the beginning of this file to better suit your needs;
    echo you can edit this file by right clicking and selecting the "edit" option from the dropdown.
    exit /b
)

rem print banner and whatnot
echo   __  __ ____ _____   ^| Convert MP3 Files to MP4 Files!
echo  ^|  ^\/  ^|  _ ^\___ /   ^| Developed by phonkanon
echo  ^| ^|^\/^| ^| ^|_) ^|^|_ ^\   ^| https://github.com/phonkanon
echo  ^| ^|  ^| ^|  __/___) ^|  ^| version 1.0
echo  ^|_^|  ^|_^|_^|  ^|____/   ^| 
echo         ^|___ ^\        ^| Constant Arguments
echo           __) ^|       ^| Resize Cover Art: %RESIZE_COVER_ART%
echo          / __/        ^| Cover Art Size: %COVER_ART_SIZE%x%COVER_ART_SIZE%
echo   ______^|_____^|_  _   ^| Approx. Filesize Offset (KB): %APPROXSIZE_OFFSET_KB%
echo  ^|  ^\/  ^|  _ ^\^| ^|^| ^|  ^|
echo  ^| ^|^\/^| ^| ^|_) ^| ^|^| ^|_ ^|
echo  ^| ^|  ^| ^|  __/^|__   _^|^|
echo  ^|_^|  ^|_^|_^|      ^|_^|  ^|
echo                       ^|

rem set the first argument to the input file, second to the format
set "input=%~1"
set "format=%~2"

rem check for the delete flag
set deletefile=no
if /I "%~3" == "-delete" (
    set deletefile=yes
)

rem Extract Metadata
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format_tags^=artist -of default^=nw^=1^:nk^=1 "%input%"') do set "artist=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format_tags^=title -of default^=nw^=1^:nk^=1 "%input%"') do set "title=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format_tags^=album -of default^=nw^=1^:nk^=1 "%input%"') do set "album=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=pix_fmt -of default^=nw^=1^:nk^=1 "%input%"') do set "pix_fmt=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -select_streams a -show_entries stream^=bit_rate -of default^=nw^=1^:nk^=1 "%input%"') do set "bit_rate=%%A"

rem get the width for the cover art (assume it's a square)
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=width -of default^=nw^=1^:nk^=1 "%input%"') do set "coverwidth=%%A"

rem Gather some information required to calculate the approx. filesize
for /f "tokens=*" %%A in ('ffprobe -loglevel error -select_streams a -show_entries stream^=duration -of default^=nw^=1^:nk^=1 "%input%"') do set "duration=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format^=size -of default^=nw^=1^:nk^=1 "%input%"') do set "filesize=%%A"

echo ----------EXTRACTED META/INFO----------
echo Title: %title%
echo Artist: %artist%
echo Album: %album%
if [%pix_fmt%]==[] (
    echo Cover Art: False
    echo ^[MP32MP4^] No Cover Art Found. Please try again with a compatible mp3 file.
    ) else (
        echo Cover Art: True
        echo Cover Art Size: %coverwidth%x%coverwidth%
        echo Pixel Format: %pix_fmt%
        )
echo Bitrate: %bit_rate%
echo Duration: %duration%
echo Filesize in bytes: %filesize% 
echo ---------------------------------------

rem if no format string is provided and metadata exists, use {title}-{artist} format
if not defined format (
    if defined artist if defined title (
        set "format={title}-{artist}"
    ) else (
        set "format=%~n1"
    )
)

rem check if format contains any of the format specifiers
echo %format% | findstr /C:"{artist}" /C:"{title}" /C:"{album}" > nul
if errorlevel 1 (
    rem No format specifiers found, treating format as direct output filename
    set "outputname=%format%"
) else (
    rem Replace placeholders in format string with metadata
    set "outputname=!format:{artist}=%artist%!"
    set "outputname=!outputname:{title}=%title%!"
    set "outputname=!outputname:{album}=%album%!"
)

rem Sanitize the output filename
call :sanitize outputname

rem extract cover art
set "coverfilename=cover_%RANDOM%.jpg"
ffmpeg -loglevel panic -i "%input%" -an -codec:v copy "%coverfilename%"
echo ^[MP32MP4^] Successfully Extracted Cover Art from MP3

rem compress cover art a little
magick convert -quality 25 -strip %coverfilename% %coverfilename%
echo ^[IMGProcessor^] Successfully Compressed %coverfilename%

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

rem calculate approximate filesize
set /a byterate=bit_rate/8
set /a audiorate=byterate*duration
set /a approxsize=audiorate+coversize
set /a approxsize=approxsize/1000
set /a approxsize=approxsize+APPROXSIZE_OFFSET_KB
set "approxsize=%approxsize% kb"

rem print filename and stuff to the console
echo ^[MP32MP4^] Now Converting %input% and saving to %outputname%.mp4

rem print output stuff
echo ----------OUTPUT INFORMATION----------
echo Filename: %outputname%.mp4
echo Cover Art Filename: %coverfilename%
echo Filetype: mp4
echo Audio Codec: aac
echo Video Codec: libx264
echo Video Dimensions: %coverwidth%x%coverwidth%
echo Approx. Video Size: %approxsize%
echo --------------------------------------

rem create an MP4 video
ffmpeg -loop 1 -framerate 1 -loglevel error -stats -i %coverfilename% -i "%input%" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:a aac -b:a %bit_rate% -c:v libx264 -crf 23 -threads 0 -t %duration% "!outputname!.mp4"

rem delete cover art and clean up after ourselves
del %coverfilename%
del null

rem delete input file if delete flag was found
if /I "%deletefile%" == "yes" (
    del "%input%"
)

endlocal

goto :eof
rem create a way to sanitize the filenames
:sanitize
for %%i in (^< ^> ^: / \ ^| ? *) do (
    set %1=!%1:%%i=_!
)
goto :eof