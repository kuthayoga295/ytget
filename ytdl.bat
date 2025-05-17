@echo off
setlocal enabledelayedexpansion
set "OUTDIR=%USERPROFILE%\Downloads"
:MENU
cls
echo ==============================
echo              YTDL
echo ==============================
set /p URL=Masukkan URL YouTube:
if "%URL%"=="" (
    echo [ERROR] URL tidak boleh kosong.
    pause
    goto MENU
)

echo [1] Download Video MKV
echo [2] Download Audio MP3
echo [3] Exit
echo ==============================
set /p PILIH=Masukkan pilihan [1-3]:

if "%PILIH%"=="1" goto VIDEO
if "%PILIH%"=="2" goto AUDIO
if "%PILIH%"=="3" goto EXIT
echo.
echo Pilihan tidak valid!
pause
goto MENU

:VIDEO
echo.
echo Pilih codec video:
echo [1] All (default)
echo [2] AVC / H.264
echo [3] VP9
echo [4] AV1
set /p CODEC=Kode codec [1-4]:

if "%CODEC%"=="2" ( set FILTER=[vcodec*=avc1] )
if "%CODEC%"=="3" ( set FILTER=[vcodec*=vp] )
if "%CODEC%"=="4" ( set FILTER=[vcodec*=av01] )
if not defined FILTER set FILTER=

echo.
echo Pilih resolusi video (contoh: 720, 1080, 1440, 2160):
set /p RESOLUSI=Resolusi:

echo.
echo Mengunduh video %RESOLUSI%p ke MKV di folder Downloads...
yt-dlp -f "bv[height<=%RESOLUSI%%FILTER%]+ba" --merge-output-format mkv -o "%OUTDIR%\%%(title)s.%%(ext)s" %URL%
pause
goto MENU

:AUDIO
echo.
echo Mengunduh audio dan mengonversi ke MP3 ke folder Downloads...
yt-dlp -f "bestaudio" --extract-audio --audio-format mp3 -o "%OUTDIR%\%%(title)s.%%(ext)s" %URL%
pause
goto MENU

:EXIT
echo.
exit
