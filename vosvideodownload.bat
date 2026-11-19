:: TURN INTO ".BAT" TO USE.
:: ANY FALSE USE OF THIS PROGRAM CAN RESULT IN COPYRIGHT INFRINGEMENT TO THE RESPECTIVE AUTHORS.
@echo off
title VOSVIDEODOWNLOAD
set "VERSION=1.03.23"
set "VERSION_TYPE=RELEASE"
set "OPERATING_SYSTEM=Windows 11/PC"
set "UPDATE_URL=https://raw.githubusercontent.com/vrederik123/VOSVideoDownload---Updates/main/vosvideodownload.bat"
:: START IN THE BORDERLESS TERMINAL STYLE
call :set_display_mode FULLSCREEN

:init
:: LOAD LOCAL DEPENDENCIES PATH, ANSI COLORS, AND SETTINGS.TXT
:: Keep required Windows paths while excluding user-installed dependency paths.
set "PATH=%~dp0DEPENDENCIES;%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0"
for /f "delims=" %%A in ('powershell -NoProfile -Command "[char]27"') do set "ESC=%%A"
set "RED=%ESC%[91m"&set "DARKRED=%ESC%[31m"&set "ORANGE=%ESC%[38;5;208m"&set "YELLOW=%ESC%[93m"&set "GREEN=%ESC%[92m"&set "CYAN=%ESC%[96m"&set "RESET=%ESC%[0m"
set "PURPLE=%ESC%[35m"&set "PINK=%ESC%[95m"&set "WHITE=%ESC%[97m"
if not exist "%~dp0settings.txt" (
    echo METADATA=DISABLED> "%~dp0settings.txt"
    echo FLAME=STANDARD>> "%~dp0settings.txt"
)
set "METADATA=DISABLED"
set "FLAME=STANDARD"
for /f "usebackq tokens=1,2 delims==" %%A in ("%~dp0settings.txt") do (
    if /i "%%A"=="METADATA" set "METADATA=%%B"
    if /i "%%A"=="FLAME" set "FLAME=%%B"
)
if /i "%FLAME%"=="YELLOW-WHITE" (
    set "FLAME=STANDARD"
    call :save_settings
)
call :set_flame

:menu
call :banner
echo %RED%WELCOME TO VOSVIDEODOWNLOAD - THE GO-TO VIDEO DOWNLOADER%RESET%
echo %GREEN%1: DOWNLOAD VIDEO%RESET%
echo %GREEN%2: DEPENDENCIES%RESET%
echo %GREEN%3: UPDATE VOSVIDEODOWNLOAD%RESET%
echo %GREEN%4: VOSVIDEODOWNLOAD SETTINGS%RESET%
echo %GREEN%5: QUIT%RESET%
echo %GREEN%6: RESTART%RESET%
set "c="&set /p "c="
if "%c%"=="" goto toggle_display
if "%c%"=="1" goto download_menu
if "%c%"=="2" goto dependencies
if "%c%"=="3" goto update
if "%c%"=="4" goto settings
if "%c%"=="5" exit
if "%c%"=="6" goto init
goto menu

:toggle_display
call :set_display_mode TOGGLE
goto menu

:download_menu
call :banner
echo %RED%DOWNLOAD OPTIONS%RESET%
echo %GREEN%1: DOWNLOAD VIDEO%RESET%
echo %GREEN%2: DOWNLOAD AUDIO%RESET%
echo %GREEN%3: DOWNLOAD VIDEO ONLY (NO AUDIO)%RESET%
echo %GREEN%4: DOWNLOAD ALL VIDEOS ON CHANNEL%RESET%
echo %GREEN%5: DOWNLOAD ALL SHORTS ON CHANNEL%RESET%
echo %CYAN%ENTER: BACK TO MAIN MENU%RESET%
set "m="&set /p "m="
if "%m%"=="" goto menu
set "P="&set "S="&set "A="
if "%m%"=="1" (set "P=PASTE VIDEO URL"&set "A=-f "bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]" --merge-output-format mp4")
if "%m%"=="2" (set "P=PASTE URL FOR AUDIO"&set "A=-x --audio-format mp3 --audio-quality 0")
if "%m%"=="3" (set "P=PASTE URL FOR VIDEO ONLY"&set "A=-f "bv*[vcodec^=avc1]/bv*[ext=mp4]" --merge-output-format mp4")
if "%m%"=="4" (set "P=PASTE CHANNEL /VIDEOS URL"&set "A=-f "bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]" --merge-output-format mp4"&set "S=%%(channel)s - VIDEOS/")
if "%m%"=="5" (set "P=PASTE CHANNEL /SHORTS URL"&set "A=-f "bv*[vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]" --merge-output-format mp4"&set "S=%%(channel)s - SHORTS/")
if "%P%"=="" goto download_menu
call :banner
set "url="&set /p "url=%RED%%P% %CYAN%(OR PRESS ENTER TO GO BACK)%RED%: %RESET%"
if "%url%"=="" goto download_menu
if not exist "%~dp0DEPENDENCIES\yt-dlp.exe" (
    echo %RED%YT-DLP IS MISSING. INSTALL DEPENDENCIES FIRST.%RESET%
    set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
    goto download_menu
)
if /i "%METADATA%"=="ENABLED" (
    "%~dp0DEPENDENCIES\yt-dlp.exe" --ffmpeg-location "%~dp0DEPENDENCIES" -P "%~dp0VIDEOS" -o "%S%%%(title)s/%%(title)s.%%(ext)s" %A% --write-description --write-thumbnail --convert-thumbnails jpg "%url%"
) else (
    "%~dp0DEPENDENCIES\yt-dlp.exe" --ffmpeg-location "%~dp0DEPENDENCIES" -P "%~dp0VIDEOS" -o "%S%%%(title)s.%%(ext)s" %A% "%url%"
)
if errorlevel 1 goto download_failed
echo.&echo %GREEN%DONE! SAVED TO THE VIDEOS FOLDER.%RESET%
set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
goto download_menu

:download_failed
echo.&echo %RED%DOWNLOAD FAILED. YT-DLP RETURNED ERROR CODE %ERRORLEVEL%. CHECK THE URL, NETWORK, AND DEPENDENCIES.%RESET%
set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
goto download_menu

:update
call :banner
echo %RED%CHECKING FOR VOSVIDEODOWNLOAD UPDATES...%RESET%
set "updateFile=%TEMP%\VOSVideoDownload-latest-%RANDOM%.bat"
set "updateHelper=%TEMP%\VOSVideoDownload-update-%RANDOM%.bat"
set "updateUrl=%UPDATE_URL%?cache=%RANDOM%%RANDOM%"
set "VOS_UPDATE_FILE=%updateFile%"
set "VOS_UPDATE_URL=%updateUrl%"
set "VOS_UPDATE_HELPER=%updateHelper%"
echo %CYAN%DOWNLOADING UPDATE...%RESET%
where curl.exe >nul 2>&1
if errorlevel 1 goto update_download_powershell
curl.exe --location --fail --silent --show-error --connect-timeout 10 --max-time 30 "%updateUrl%" --output "%updateFile%"
if errorlevel 1 goto update_download_failed
goto update_download_validate

:update_download_powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $request=[System.Net.HttpWebRequest]::Create($env:VOS_UPDATE_URL); $request.Timeout=30000; $request.ReadWriteTimeout=30000; $response=$request.GetResponse(); try { $stream=$response.GetResponseStream(); $file=[System.IO.File]::Create($env:VOS_UPDATE_FILE); try { $stream.CopyTo($file) } finally { $file.Dispose(); $stream.Dispose() } } finally { $response.Dispose() }"
if errorlevel 1 goto update_download_failed

:update_download_validate
if not exist "%updateFile%" goto update_download_failed
for %%A in ("%updateFile%") do if %%~zA LSS 100 goto update_download_failed
set "remoteVersion="
for /f "delims=" %%A in ('powershell -NoProfile -Command "$content=Get-Content -Raw -LiteralPath $env:VOS_UPDATE_FILE; if ($content -match 'VERSION=([0-9]+(?:\.[0-9]+)*)') { $matches[1] }"') do set "remoteVersion=%%A"
if "%remoteVersion%"=="" (
    del /f /q "%updateFile%" >nul 2>&1
    echo %RED%THE DOWNLOADED UPDATE DOES NOT CONTAIN A VALID VERSION.%RESET%
    set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
    goto menu
)
set "remoteVersionType="
for /f "delims=" %%A in ('powershell -NoProfile -Command "$content=Get-Content -Raw -LiteralPath $env:VOS_UPDATE_FILE; if ($content -match 'VERSION_TYPE=([A-Za-z0-9_-]+)') { $matches[1] }"') do set "remoteVersionType=%%A"
if "%remoteVersionType%"=="" echo %YELLOW%WARNING: UPDATE VERSION TYPE MISSING; HISTORY WILL RECORD UNKNOWN.%RESET%
if "%remoteVersionType%"=="" set "remoteVersionType=UNKNOWN"
set "currentVersion=%VERSION%"
set "VOS_REMOTE_VERSION=%remoteVersion%"
set "VOS_CURRENT_VERSION=%currentVersion%"
set "VOS_REMOTE_VERSION_TYPE=%remoteVersionType%"
set "VOS_CURRENT_VERSION_TYPE=%VERSION_TYPE%"
set "updateStatus="
for /f "delims=" %%A in ('powershell -NoProfile -Command "try { [version]$new=[version]$env:VOS_REMOTE_VERSION; [version]$old=[version]$env:VOS_CURRENT_VERSION; $typeChanged=$env:VOS_REMOTE_VERSION_TYPE -ne 'UNKNOWN' -and -not [string]::Equals($env:VOS_REMOTE_VERSION_TYPE,$env:VOS_CURRENT_VERSION_TYPE,[StringComparison]::OrdinalIgnoreCase); if ($new -gt $old -or $typeChanged) { 'NEW' } else { 'CURRENT' } } catch { 'INVALID' }"') do set "updateStatus=%%A"
if "%updateStatus%"=="INVALID" (
    del /f /q "%updateFile%" >nul 2>&1
    echo %RED%THE UPDATE VERSION IS INVALID.%RESET%
    set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
    goto menu
)
if "%updateStatus%"=="CURRENT" (
    del /f /q "%updateFile%" >nul 2>&1
    echo %GREEN%VOSVIDEODOWNLOAD %currentVersion% IS ALREADY UP TO DATE.%RESET%
    set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
    goto menu
)
echo %CYAN%UPDATE FOUND: %currentVersion% TO %remoteVersion%%RESET%
powershell -NoProfile -Command "$barSize=20; $fill=[string][char]9608; for($i=0;$i -le $barSize;$i++){ $bar=($fill * $i)+(' ' * ($barSize-$i)); $line=[string][char]13+('{0} {1,5:0.0}' -f $bar,[double](100*$i/$barSize))+[char]37; Write-Host $line -NoNewline -ForegroundColor Green; if($i -lt $barSize){Start-Sleep -Milliseconds 25} }; Start-Sleep -Milliseconds 500; Write-Host; Write-Host 'UPDATE COMPLETE' -ForegroundColor Cyan"
set /p "e=%CYAN%PRESS ENTER TO APPLY THE UPDATE AND RESTART%RESET%"
(
    echo @echo off
    echo copy /y "%updateFile%" "%~f0" ^>nul
    echo if errorlevel 1 goto cleanup
    echo if not exist "%~dp0history.txt" echo VOSVIDEODOWNLOAD UPDATE HISTORY LOG^>"%~dp0history.txt"
    echo powershell -NoProfile -Command "$date=Get-Date -Format 'MM/dd/yyyy'; $time=Get-Date -Format 'hh:mm tt'; $entry='UPDATE: %currentVersion% (%VERSION_TYPE%) '+[char]62+' %remoteVersion% (%remoteVersionType%) AT '+$date+' AT '+$time; Add-Content -LiteralPath '%~dp0history.txt' -Value $entry -Encoding UTF8"
    echo if errorlevel 1 echo WARNING: UPDATE INSTALLED, BUT THE UPDATE HISTORY COULD NOT BE WRITTEN.
    echo start "" /b "%~f0"
    echo :cleanup
    echo del /f /q "%updateFile%" ^>nul 2^>^&1
    echo start "" /b powershell -NoProfile -Command "Start-Sleep -Seconds 2; Remove-Item -LiteralPath $env:VOS_UPDATE_HELPER -Force -ErrorAction SilentlyContinue"
) > "%updateHelper%"
start "" /b cmd /d /c ""%updateHelper%""
exit

:update_download_failed
if exist "%updateFile%" del /f /q "%updateFile%" >nul 2>&1
echo %RED%UPDATE DOWNLOAD FAILED OR TIMED OUT. CHECK THE ERROR ABOVE AND YOUR CONNECTION.%RESET%
set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
goto menu

:dependencies
call :banner
echo %RED%DEPENDENCIES%RESET%
echo %GREEN%1: CHECK IF DEPENDENCIES ARE DOWNLOADED%RESET%
echo %GREEN%2: DOWNLOAD DEPENDENCIES%RESET%
echo %GREEN%3: UPDATE DEPENDENCIES%RESET%
echo %GREEN%4: DELETE DEPENDENCIES%RESET%
echo %CYAN%ENTER: BACK TO MAIN MENU%RESET%
set "dc="&set /p "dc="
if "%dc%"=="" goto menu
if "%dc%"=="1" goto dep_check
if "%dc%"=="2" goto dep_dl
if "%dc%"=="3" goto dep_up
if "%dc%"=="4" goto dep_del
goto dependencies

:dep_check
call :banner
set "miss=0"
for %%D in (yt-dlp ffmpeg ffprobe ffplay) do call :check_one "%%D"
echo.
if not "%miss%"=="1" goto dep_check_success
echo %RED%ONE OR MORE LOCAL DEPENDENCY FILES ARE MISSING.%RESET%
echo %RED%WOULD YOU LIKE TO INSTALL/REPAIR THE DEPENDENCIES?%RESET%
echo %GREEN%[Y] YES ^| [N] NO%RESET%
set "yn="&set /p "yn="
if /i "%yn%"=="Y" goto dep_dl
goto dependencies

:dep_check_success
echo %GREEN%ALL LOCAL DEPENDENCY FILES ARE PRESENT.%RESET%
set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
goto dependencies

:check_one
if not exist "%~dp0DEPENDENCIES\%~1.exe" (
    echo %RED%[MISSING] %~1 IS NOT INSTALLED.%RESET%
    set "miss=1"
    exit /b 0
)
echo %GREEN%[OK] %~1 IS PRESENT LOCALLY.%RESET%
exit /b 0

:dep_dl
call :banner
echo %RED%INSTALLING YT-DLP, FFMPEG, FFPROBE, AND FFPLAY...%RESET%
call :fetch_local_dependencies
if errorlevel 1 (
    set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
    goto dependencies
)
echo %GREEN%LOCAL DEPENDENCY FILES INSTALLED.%RESET%
echo %GREEN%INSTALL LOCATION: %~dp0DEPENDENCIES%RESET%
set /p "e=%CYAN%PRESS ENTER TO RESTART%RESET%"
start "" "%~f0"
exit

:dep_up
call :banner
echo %RED%UPDATING YT-DLP, FFMPEG, FFPROBE, AND FFPLAY...%RESET%
call :fetch_local_dependencies
if errorlevel 1 (
    set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
    goto dependencies
)
echo %GREEN%LOCAL DEPENDENCY FILES UPDATED.%RESET%
set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
goto dependencies

:fetch_local_dependencies
set "depTemp=%TEMP%\VOSVideoDownload-dependencies-%RANDOM%-%RANDOM%"
set "VOS_DEPENDENCY_DIR=%~dp0DEPENDENCIES"
set "VOS_DEPENDENCY_TEMP=%depTemp%"
set "VOS_DEPENDENCY_YTDLP=%depTemp%\yt-dlp.exe"
set "VOS_DEPENDENCY_FFMPEG=%depTemp%\ffmpeg-release-essentials.zip"
if not exist "%VOS_DEPENDENCY_DIR%" mkdir "%VOS_DEPENDENCY_DIR%"
if not exist "%VOS_DEPENDENCY_DIR%" goto fetch_dependencies_failed
if not exist "%depTemp%" mkdir "%depTemp%"
if not exist "%depTemp%" goto fetch_dependencies_failed
where curl.exe >nul 2>&1
if errorlevel 1 goto fetch_dependencies_failed
curl.exe --location --fail --show-error --retry 2 --connect-timeout 15 --max-time 300 "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" --output "%VOS_DEPENDENCY_YTDLP%"
if errorlevel 1 goto fetch_dependencies_failed
curl.exe --location --fail --show-error --retry 2 --connect-timeout 15 --max-time 600 "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" --output "%VOS_DEPENDENCY_FFMPEG%"
if errorlevel 1 goto fetch_dependencies_failed
for %%A in ("%VOS_DEPENDENCY_YTDLP%") do if %%~zA LSS 1000000 goto fetch_dependencies_failed
for %%A in ("%VOS_DEPENDENCY_FFMPEG%") do if %%~zA LSS 10000000 goto fetch_dependencies_failed
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $extract=Join-Path $env:VOS_DEPENDENCY_TEMP 'ffmpeg-extracted'; Expand-Archive -LiteralPath $env:VOS_DEPENDENCY_FFMPEG -DestinationPath $extract -Force; $ffmpeg=Get-ChildItem -LiteralPath $extract -Filter 'ffmpeg.exe' -File -Recurse | Select-Object -First 1; if(-not $ffmpeg){throw 'FFmpeg archive did not contain ffmpeg.exe'}; $bin=$ffmpeg.DirectoryName; foreach($name in @('ffmpeg.exe','ffprobe.exe','ffplay.exe')){if(-not (Test-Path -LiteralPath (Join-Path $bin $name))){throw ('FFmpeg archive is missing '+$name)}}; foreach($name in @('yt-dlp.exe','ffmpeg.exe','ffprobe.exe','ffplay.exe')){Remove-Item -LiteralPath (Join-Path $env:VOS_DEPENDENCY_DIR $name) -Force -ErrorAction SilentlyContinue}; Get-ChildItem -LiteralPath $env:VOS_DEPENDENCY_DIR -File | Where-Object { $_.Name -like 'av*.dll' -or $_.Name -like 'sw*.dll' -or $_.Name -like 'postproc*.dll' } | Remove-Item -Force; Get-ChildItem -LiteralPath $bin -File | Copy-Item -Destination $env:VOS_DEPENDENCY_DIR -Force; Copy-Item -LiteralPath $env:VOS_DEPENDENCY_YTDLP -Destination (Join-Path $env:VOS_DEPENDENCY_DIR 'yt-dlp.exe') -Force"
if errorlevel 1 goto fetch_dependencies_failed
set "miss=0"
for %%D in (yt-dlp ffmpeg ffprobe ffplay) do call :check_one "%%D"
if "%miss%"=="1" goto fetch_dependencies_failed
rmdir /s /q "%depTemp%" >nul 2>&1
exit /b 0

:fetch_dependencies_failed
if defined depTemp if exist "%depTemp%" rmdir /s /q "%depTemp%" >nul 2>&1
echo %RED%DEPENDENCY DOWNLOAD OR INSTALL FAILED. REVIEW THE ERROR ABOVE AND TRY AGAIN.%RESET%
exit /b 1

:dep_del
call :banner
echo %RED%WHICH LOCAL DEPENDENCY FILES WOULD YOU LIKE TO REMOVE?%RESET%
echo %GREEN%1: YT-DLP%RESET%
echo %GREEN%2: FFMPEG (FFMPEG, FFPROBE, FFPLAY)%RESET%
echo %GREEN%3: FFPROBE ONLY%RESET%
echo %GREEN%4: FFPLAY ONLY%RESET%
echo %GREEN%5: ALL LOCAL DEPENDENCY FILES%RESET%
echo %CYAN%ENTER: GO BACK%RESET%
set "x="&set /p "x="
if "%x%"=="" goto dependencies
if "%x%"=="1" (
    del /f /q "%~dp0DEPENDENCIES\yt-dlp.exe" >nul 2>&1
    echo %GREEN%LOCAL YT-DLP FILE REMOVED IF IT WAS PRESENT. GLOBAL INSTALLATIONS WERE NOT REMOVED.%RESET%
)
if "%x%"=="2" (
    del /f /q "%~dp0DEPENDENCIES\ffmpeg.exe" "%~dp0DEPENDENCIES\ffprobe.exe" "%~dp0DEPENDENCIES\ffplay.exe" >nul 2>&1
    del /f /q "%~dp0DEPENDENCIES\av*.dll" "%~dp0DEPENDENCIES\sw*.dll" "%~dp0DEPENDENCIES\postproc*.dll" >nul 2>&1
    for /d %%D in ("%~dp0DEPENDENCIES\ffmpeg*") do if exist "%%~fD" rmdir /s /q "%%~fD"
    echo %GREEN%LOCAL FFMPEG FILES REMOVED IF PRESENT. GLOBAL INSTALLATIONS WERE NOT REMOVED.%RESET%
)
if "%x%"=="3" (
    del /f /q "%~dp0DEPENDENCIES\ffprobe.exe" >nul 2>&1
    echo %GREEN%LOCAL FFPROBE FILE REMOVED IF IT WAS PRESENT.%RESET%
)
if "%x%"=="4" (
    del /f /q "%~dp0DEPENDENCIES\ffplay.exe" >nul 2>&1
    echo %GREEN%LOCAL FFPLAY FILE REMOVED IF IT WAS PRESENT.%RESET%
)
if "%x%"=="5" (
    if exist "%~dp0DEPENDENCIES" rmdir /s /q "%~dp0DEPENDENCIES"
    echo %GREEN%LOCAL DEPENDENCIES FOLDER REMOVED. GLOBAL INSTALLATIONS WERE NOT REMOVED.%RESET%
)
if not "%x%"=="1" if not "%x%"=="2" if not "%x%"=="3" if not "%x%"=="4" if not "%x%"=="5" goto dependencies
set /p "e=%CYAN%PRESS ENTER TO CONTINUE%RESET%"
goto dependencies

:settings
call :banner
for %%D in (yt-dlp ffmpeg ffprobe ffplay) do if exist "%~dp0DEPENDENCIES\%%D.exe" (set "st_%%D=%YELLOW%INSTALLED") else (set "st_%%D=%RED%NOT INSTALLED")
set "vc=0"
if exist "%~dp0VIDEOS\*" for /f %%A in ('powershell -NoProfile -Command "$p='%~dp0VIDEOS'; if (Test-Path -LiteralPath $p) { (Get-ChildItem -LiteralPath $p -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '^\.(mp4|mp3|mkv|webm|m4a|wav|mov|avi|flv|ogg|opus|aac|wmv)$' } | Measure-Object).Count } else { 0 }"') do set "vc=%%A"
set "updateCount=0"
if exist "%~dp0history.txt" set "updateCount=ERROR"
if exist "%~dp0history.txt" for /f %%A in ('powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $count=(Get-Content -LiteralPath '%~dp0history.txt' | Measure-Object -Line).Lines; [Math]::Max(0,$count-1)"') do set "updateCount=%%A"
echo %RED%VOSVIDEODOWNLOAD SETTINGS%RESET%
echo %GREEN%VERSION: %YELLOW%%VERSION% ^| %VERSION_TYPE%%RESET%
echo %GREEN%UPDATES INSTALLED: %YELLOW%%updateCount%%RESET%
echo %GREEN%INTENDED OPERATING SYSTEM: %YELLOW%%OPERATING_SYSTEM%%RESET%
echo %GREEN%DEPENDENCIES:%RESET%
echo %GREEN% - YT-DLP: %st_yt-dlp%%RESET%
echo %GREEN% - FFMPEG: %st_ffmpeg%%RESET%
echo %GREEN% - FFPROBE: %st_ffprobe%%RESET%
echo %GREEN% - FFPLAY: %st_ffplay%%RESET%
echo %GREEN%VIDEOS DOWNLOADED: %YELLOW%%vc%%RESET%&echo.
echo %GREEN%SETTINGS%RESET%
echo %GREEN%1: TOGGLE METADATA/THUMBNAIL: %YELLOW%%METADATA%%RESET%
echo %GREEN%2: ASCII FLAME: %YELLOW%%FLAME_DISPLAY%%RESET%
echo %CYAN%ENTER: BACK TO MAIN MENU%RESET%
set "sc="&set /p "sc="
if "%sc%"=="" goto menu
if "%sc%"=="1" (
    if /i "%METADATA%"=="DISABLED" (set "METADATA=ENABLED") else (set "METADATA=DISABLED")
    call :save_settings
)
if "%sc%"=="2" goto flame_settings
goto settings

:flame_settings
call :banner
set "FLAME_STANDARD_LABEL="
set "FLAME_PURPLE_LABEL="
set "FLAME_GREEN_LABEL="
set "FLAME_ICE_LABEL="
set "FLAME_OCEAN_LABEL="
set "FLAME_SUNSET_LABEL="
set "FLAME_CYBERPUNK_LABEL="
set "FLAME_RAINBOW_LABEL="
if /i "%FLAME%"=="STANDARD" set "FLAME_STANDARD_LABEL=(ENABLED) "
if /i "%FLAME%"=="PURPLE-PINK" set "FLAME_PURPLE_LABEL=(ENABLED) "
if /i "%FLAME%"=="GREEN-WHITE" set "FLAME_GREEN_LABEL=(ENABLED) "
if /i "%FLAME%"=="ICE-BLUE" set "FLAME_ICE_LABEL=(ENABLED) "
if /i "%FLAME%"=="OCEAN-TEAL" set "FLAME_OCEAN_LABEL=(ENABLED) "
if /i "%FLAME%"=="SUNSET" set "FLAME_SUNSET_LABEL=(ENABLED) "
if /i "%FLAME%"=="CYBERPUNK" set "FLAME_CYBERPUNK_LABEL=(ENABLED) "
if /i "%FLAME%"=="RAINBOW" set "FLAME_RAINBOW_LABEL=(ENABLED) "
echo %GREEN%ASCII FLAME SETTINGS%RESET%
echo %GREEN%1: %FLAME_STANDARD_LABEL%RED-YELLOW FLAME%RESET%
echo %GREEN%2: %FLAME_PURPLE_LABEL%PURPLE-PINK FLAME%RESET%
echo %GREEN%3: %FLAME_GREEN_LABEL%GREEN-WHITE FLAME%RESET%
echo %GREEN%4: %FLAME_ICE_LABEL%ICE-BLUE FLAME%RESET%
echo %GREEN%5: %FLAME_OCEAN_LABEL%OCEAN-TEAL FLAME%RESET%
echo %GREEN%6: %FLAME_SUNSET_LABEL%SUNSET FLAME%RESET%
echo %GREEN%7: %FLAME_CYBERPUNK_LABEL%CYBERPUNK FLAME%RESET%
echo %GREEN%8: %FLAME_RAINBOW_LABEL%RAINBOW FLAME%RESET%
echo %CYAN%ENTER: BACK TO SETTINGS%RESET%
set "fc="&set /p "fc="
if "%fc%"=="" goto settings
if "%fc%"=="1" set "FLAME=STANDARD"
if "%fc%"=="2" set "FLAME=PURPLE-PINK"
if "%fc%"=="3" set "FLAME=GREEN-WHITE"
if "%fc%"=="4" set "FLAME=ICE-BLUE"
if "%fc%"=="5" set "FLAME=OCEAN-TEAL"
if "%fc%"=="6" set "FLAME=SUNSET"
if "%fc%"=="7" set "FLAME=CYBERPUNK"
if "%fc%"=="8" set "FLAME=RAINBOW"
if not "%fc%"=="1" if not "%fc%"=="2" if not "%fc%"=="3" if not "%fc%"=="4" if not "%fc%"=="5" if not "%fc%"=="6" if not "%fc%"=="7" if not "%fc%"=="8" goto flame_settings
call :set_flame
call :save_settings
goto settings

:save_settings
> "%~dp0settings.txt" echo METADATA=%METADATA%
>> "%~dp0settings.txt" echo FLAME=%FLAME%
exit /b

:set_flame
if /i "%FLAME%"=="PURPLE-PINK" (
    set "FLAME_DISPLAY=PURPLE-PINK FLAME"
    set "FLAME1=%ESC%[38;2;80;0;150m"
    set "FLAME2=%ESC%[38;2;105;0;185m"
    set "FLAME3=%ESC%[38;2;130;0;215m"
    set "FLAME4=%ESC%[38;2;155;0;235m"
    set "FLAME5=%ESC%[38;2;180;0;245m"
    set "FLAME6=%ESC%[38;2;205;10;240m"
    set "FLAME7=%ESC%[38;2;225;30;230m"
    set "FLAME8=%ESC%[38;2;240;65;225m"
    set "FLAME9=%ESC%[38;2;250;115;232m"
    set "FLAME10=%ESC%[38;2;255;185;245m"
    exit /b
)
if /i "%FLAME%"=="GREEN-WHITE" (
    set "FLAME_DISPLAY=GREEN-WHITE FLAME"
    set "FLAME1=%ESC%[38;2;0;65;20m"
    set "FLAME2=%ESC%[38;2;0;95;30m"
    set "FLAME3=%ESC%[38;2;0;125;40m"
    set "FLAME4=%ESC%[38;2;0;155;50m"
    set "FLAME5=%ESC%[38;2;0;180;65m"
    set "FLAME6=%ESC%[38;2;25;205;90m"
    set "FLAME7=%ESC%[38;2;65;225;125m"
    set "FLAME8=%ESC%[38;2;110;240;165m"
    set "FLAME9=%ESC%[38;2;175;250;210m"
    set "FLAME10=%ESC%[38;2;245;255;250m"
    exit /b
)
if /i "%FLAME%"=="ICE-BLUE" (
    set "FLAME_DISPLAY=ICE-BLUE FLAME"
    set "FLAME1=%ESC%[38;2;18;18;95m"
    set "FLAME2=%ESC%[38;2;25;35;135m"
    set "FLAME3=%ESC%[38;2;25;55;175m"
    set "FLAME4=%ESC%[38;2;30;80;215m"
    set "FLAME5=%ESC%[38;2;35;110;245m"
    set "FLAME6=%ESC%[38;2;40;145;255m"
    set "FLAME7=%ESC%[38;2;65;175;255m"
    set "FLAME8=%ESC%[38;2;105;205;255m"
    set "FLAME9=%ESC%[38;2;155;230;255m"
    set "FLAME10=%ESC%[38;2;220;250;255m"
    exit /b
)
if /i "%FLAME%"=="OCEAN-TEAL" (
    set "FLAME_DISPLAY=OCEAN-TEAL FLAME"
    set "FLAME1=%ESC%[38;2;0;25;55m"
    set "FLAME2=%ESC%[38;2;0;45;90m"
    set "FLAME3=%ESC%[38;2;0;70;120m"
    set "FLAME4=%ESC%[38;2;0;100;145m"
    set "FLAME5=%ESC%[38;2;0;130;155m"
    set "FLAME6=%ESC%[38;2;0;160;155m"
    set "FLAME7=%ESC%[38;2;25;190;155m"
    set "FLAME8=%ESC%[38;2;80;215;175m"
    set "FLAME9=%ESC%[38;2;145;235;205m"
    set "FLAME10=%ESC%[38;2;210;255;235m"
    exit /b
)
if /i "%FLAME%"=="SUNSET" (
    set "FLAME_DISPLAY=SUNSET FLAME"
    set "FLAME1=%ESC%[38;2;38;0;85m"
    set "FLAME2=%ESC%[38;2;70;0;130m"
    set "FLAME3=%ESC%[38;2;105;0;160m"
    set "FLAME4=%ESC%[38;2;145;10;175m"
    set "FLAME5=%ESC%[38;2;185;20;160m"
    set "FLAME6=%ESC%[38;2;220;35;130m"
    set "FLAME7=%ESC%[38;2;245;65;95m"
    set "FLAME8=%ESC%[38;2;255;100;65m"
    set "FLAME9=%ESC%[38;2;255;150;55m"
    set "FLAME10=%ESC%[38;2;255;210;100m"
    exit /b
)
if /i "%FLAME%"=="CYBERPUNK" (
    set "FLAME_DISPLAY=CYBERPUNK FLAME"
    set "FLAME1=%ESC%[38;2;20;10;75m"
    set "FLAME2=%ESC%[38;2;45;20;150m"
    set "FLAME3=%ESC%[38;2;80;25;220m"
    set "FLAME4=%ESC%[38;2;130;35;255m"
    set "FLAME5=%ESC%[38;2;190;40;255m"
    set "FLAME6=%ESC%[38;2;245;35;220m"
    set "FLAME7=%ESC%[38;2;255;35;160m"
    set "FLAME8=%ESC%[38;2;255;65;125m"
    set "FLAME9=%ESC%[38;2;170;130;255m"
    set "FLAME10=%ESC%[38;2;85;235;255m"
    exit /b
)
if /i "%FLAME%"=="RAINBOW" (
    set "FLAME_DISPLAY=RAINBOW FLAME"
    set "FLAME1=%ESC%[38;2;255;25;45m"
    set "FLAME2=%ESC%[38;2;255;75;0m"
    set "FLAME3=%ESC%[38;2;255;155;0m"
    set "FLAME4=%ESC%[38;2;255;225;0m"
    set "FLAME5=%ESC%[38;2;135;255;0m"
    set "FLAME6=%ESC%[38;2;0;235;100m"
    set "FLAME7=%ESC%[38;2;0;220;220m"
    set "FLAME8=%ESC%[38;2;0;125;255m"
    set "FLAME9=%ESC%[38;2;100;45;255m"
    set "FLAME10=%ESC%[38;2;255;60;200m"
    exit /b
)
set "FLAME=STANDARD"
set "FLAME_DISPLAY=RED-YELLOW FLAME"
set "FLAME1=%ESC%[38;2;120;0;0m"
set "FLAME2=%ESC%[38;2;155;0;0m"
set "FLAME3=%ESC%[38;2;190;5;0m"
set "FLAME4=%ESC%[38;2;225;20;0m"
set "FLAME5=%ESC%[38;2;250;45;0m"
set "FLAME6=%ESC%[38;2;255;80;0m"
set "FLAME7=%ESC%[38;2;255;120;0m"
set "FLAME8=%ESC%[38;2;255;165;0m"
set "FLAME9=%ESC%[38;2;255;205;0m"
set "FLAME10=%ESC%[38;2;255;240;75m"
exit /b

:set_display_mode
set "VOS_DISPLAY_TARGET=%~1"
powershell -NoProfile -Command "$ws=Add-Type -MemberDefinition '[DllImport(\"kernel32.dll\")]public static extern IntPtr GetConsoleWindow();[DllImport(\"user32.dll\")]public static extern bool ShowWindow(IntPtr h,int n);[DllImport(\"user32.dll\")]public static extern bool IsWindowVisible(IntPtr h);[DllImport(\"user32.dll\")]public static extern bool SetForegroundWindow(IntPtr h);[DllImport(\"user32.dll\")]public static extern IntPtr GetForegroundWindow();[DllImport(\"user32.dll\")]public static extern int GetWindowLong(IntPtr h,int n);[DllImport(\"user32.dll\")]public static extern void keybd_event(byte key,byte scan,uint flags,UIntPtr extra);' -Name W -Namespace N -PassThru;for($i=0;$i -lt 10;$i++){ $p=Get-Process -Name WindowsTerminal -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like '*VOSVIDEODOWNLOAD*' } | Select-Object -First 1; if($p -and $p.MainWindowHandle -ne [IntPtr]::Zero){$h=$p.MainWindowHandle;$terminal=$true}else{$h=$ws::GetConsoleWindow();$terminal=$false}; if($h -ne [IntPtr]::Zero -and ($terminal -or $ws::IsWindowVisible($h))){$style=$ws::GetWindowLong($h,-16);$fullscreen=(($style -band 0x00C00000) -eq 0);$toggle=($env:VOS_DISPLAY_TARGET -eq 'TOGGLE') -or ($env:VOS_DISPLAY_TARGET -eq 'FULLSCREEN' -and -not $fullscreen) -or ($env:VOS_DISPLAY_TARGET -eq 'WINDOWED' -and $fullscreen);if($toggle){if($env:VOS_DISPLAY_TARGET -eq 'FULLSCREEN'){$null=$ws::ShowWindow($h,3)};$null=$ws::SetForegroundWindow($h);Start-Sleep -Milliseconds 150;if($ws::GetForegroundWindow() -eq $h){if($terminal){$ws::keybd_event(0x7A,0,0,[UIntPtr]::Zero);$ws::keybd_event(0x7A,0,2,[UIntPtr]::Zero)}else{$ws::keybd_event(0x12,0,0,[UIntPtr]::Zero);$ws::keybd_event(0x0D,0,0,[UIntPtr]::Zero);$ws::keybd_event(0x0D,0,2,[UIntPtr]::Zero);$ws::keybd_event(0x12,0,2,[UIntPtr]::Zero)}}};break};Start-Sleep -Milliseconds 150}" >nul 2>&1
exit /b

:banner
cls
:: ESCAPE PIPE CHARACTERS (^|) IN ASCII ART TO PREVENT BATCH SYNTAX ERRORS
echo %FLAME1% __     __   ___    ____     __     __  ___   ____    _____    ___  %RESET%
echo %FLAME2% \ \   / /  / _ \  / ___^|    \ \   / / ^|_ _^| ^|  _ \  ^| ____^|  / _ \ %RESET%
echo %FLAME3%  \ \ / /  ^| ^| ^| ^| \___ \     \ \ / /   ^| ^|  ^| ^| ^| ^| ^|  _^|   ^| ^| ^| ^|%RESET%
echo %FLAME4%   \ V /   ^| ^|_^| ^|  ___) ^|     \ V /    ^| ^|  ^| ^|_^| ^| ^| ^|___  ^| ^|_^| ^|%RESET%
echo %FLAME5%    \_/     \___/  ^|____/       \_/    ^|___^| ^|____/  ^|_____^|  \___/ %RESET%
echo %FLAME6%  ____     ___   __        __  _   _   _        ___      _     ____  %RESET%
echo %FLAME7% ^|  _ \   / _ \  \ \      / / ^| \ ^| ^| ^| ^|      / _ \    / \   ^|  _ \ %RESET%
echo %FLAME8% ^| ^| ^| ^| ^| ^| ^| ^|  \ \ /\ / /  ^|  \^| ^| ^| ^|     ^| ^| ^| ^|  / _ \  ^| ^| ^| ^|%RESET%
echo %FLAME9% ^| ^|_^| ^| ^| ^|_^| ^|   \ V  V /   ^| ^|\  ^| ^| ^|___  ^| ^|_^| ^| / ___ \ ^| ^|_^| ^|%RESET%
echo %FLAME10% ^|____/   \___/     \_/\_/    ^|_^| \_^| ^|_____^|  \___/ /_/   \_\^|____/ %RESET%
echo.
goto :eof
