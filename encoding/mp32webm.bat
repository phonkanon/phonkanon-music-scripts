@echo off

rem allow for use with unicode
chcp 65001 > nul

rem some customizable arguments
rem set resize_cover_art to "t" to resize cover art
rem set cover_art_size to your desired size
rem tweak approxsize_offset_kb to better reflect actual output, if you'd like
rem I made it intentionally high (1200) just in case.
set "RESIZE_COVER_ART=t"
set "COVER_ART_SIZE=2048" :: 4chan max video size is 2048x2048
set /a APPROXSIZE_OFFSET_KB=1200

setlocal enabledelayedexpansion

rem check for help flag
if /I "%~1" == "-help" (
    echo Hello and Welcome to MP32WEBM, a script for converting MP3 files to webm files.
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
    echo file would be named "This Feeling-my^!lane.webm"
    echo:
    echo Third argument is optional; pass -delete to delete the input file after processing.
    echo:   
    echo Make sure to tweak the values at the beginning of this file to better suit your needs;
    echo you can edit this file by right clicking and selecting the "edit" option from the dropdown.
    exit /b
)

rem print banner and whatnot
echo          __  __ ____ _____        ^| Convert MP3 files to webms!
echo         ^|  ^\/  ^|  _ ^\___ /        ^| Developed by phonkanon
echo         ^| ^|^\/^| ^| ^|_) ^|^|_ ^\        ^| https://github.com/phonkanon
echo         ^| ^|  ^| ^|  __/___) ^|       ^| version 1.3
echo         ^|_^|__^|_^|_^|  ^|____/        ^|
echo                ^|___ ^\             ^| Constant Arguments
echo                  __) ^|            ^| Resize Cover Art: %RESIZE_COVER_ART%
echo                 / __/             ^| Cover Art Size: %COVER_ART_SIZE%x%COVER_ART_SIZE%
echo  _         _ __^|_____^|_  __  __   ^| Approx. Filesize Offset (kb): %APPROXSIZE_OFFSET_KB%
echo  ^\ ^\      / / ____^| __ )^|  ^\/  ^|  ^|
echo   ^\ ^\ /^\ / /^|  _^| ^|  _ ^\^| ^|^\/^| ^|  ^|
echo    ^\ V  V / ^| ^|___^| ^|_) ^| ^|  ^| ^|  ^|
echo     ^\_/^\_/  ^|_____^|____/^|_^|  ^|_^|  ^| 

rem set first argument to input file, second to format
set "input=%~1"
set "format=%~2"

rem check for delete flag
set deletefile=no
if /I "%~3" == "-delete" (
    set deletefile=yes
)

REM Extract metadata
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format_tags^=artist -of default^=nw^=1^:nk^=1 "%input%"') do set "artist=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format_tags^=title -of default^=nw^=1^:nk^=1 "%input%"') do set "title=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries format_tags^=album -of default^=nw^=1^:nk^=1 "%input%"') do set "album=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -show_entries stream^=pix_fmt -of default^=nw^=1^:nk^=1 "%input%"') do set "pix_fmt=%%A"
for /f "tokens=*" %%A in ('ffprobe -loglevel error -select_streams a -show_entries format^=bit_rate -of default^=nw^=1^:nk^=1 "%input%"') do set "bit_rate=%%A"

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
    echo ^[MP32WEBM^] No Cover Art Found. Please try again with a compatible mp3 file.
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
echo ^[MP32WEBM^] Successfully Extracted Cover Art from MP3

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
echo ^[MP32WEBM^] Now Converting %input% and saving to %outputname%.webm

rem print output stuff
echo ----------OUTPUT INFORMATION----------
echo Filename: %outputname%.webm
echo Cover Art Filename: %coverfilename%
echo Filetype: webm
echo Audio Codec: libopus
echo Video Codec: libvpx-vp9
echo Video Dimensions: %coverwidth%x%coverwidth%
echo Approx. Video Size: %approxsize%
echo --------------------------------------

rem create webm video
ffmpeg -loop 1 -framerate 1 -loglevel error -stats -i %coverfilename% -i "%input%" -c:a libopus -b:a %bit_rate% -c:v libvpx-vp9 -crf 30 -cpu-used 5 -tile-columns 3 -threads 0 -shortest -strict -2 -vbr on -compression_level 10 "!outputname!.webm"

rem delete cover art and clean up after ourselves
del %coverfilename%

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