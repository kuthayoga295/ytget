@echo off
setlocal enabledelayedexpansion
set "OUTDIR=%USERPROFILE%\Downloads"

:MENU
cls
echo ==============================
echo              YTDL
echo ==============================
set "URL="
set /p "URL=Enter YouTube URL: "
if "%URL%"=="" (
    echo [ERROR] URL cannot be empty.
    pause
    goto MENU
)

echo [1] Download Video as MKV
echo [2] Download Audio as MP3
echo [3] Exit
echo ==============================
set "SELECT="
set /p "SELECT=Enter choice [1-3]: "

if "%SELECT%"=="1" goto VIDEO
if "%SELECT%"=="2" goto AUDIO
if "%SELECT%"=="3" goto EXIT
echo.
echo Invalid choice!
pause
goto MENU

:VIDEO
echo.
echo Showing all available video and audio formats...
yt-dlp -F "%URL%"
echo.

set "VIDFORMAT="
set /p "VIDFORMAT=Enter video-only format ID to download: "

if "%VIDFORMAT%"=="" (
    echo [ERROR] Format ID cannot be empty!
    pause
    goto MENU
)

echo.
echo Downloading video format %VIDFORMAT% + bestaudio as MKV to Downloads folder...
yt-dlp -f "%VIDFORMAT%+bestaudio" --merge-output-format mkv -o "%OUTDIR%\%%(title)s.%%(ext)s" "%URL%"
pause
goto MENU

:AUDIO
echo.
echo Downloading best audio and converting to MP3 in Downloads folder...
yt-dlp -f "bestaudio" --extract-audio --audio-format mp3 -o "%OUTDIR%\%%(title)s.%%(ext)s" "%URL%"
pause
goto MENU

:EXIT
echo.
exit /b
