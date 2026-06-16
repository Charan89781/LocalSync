@echo off
title LocalSync Helper Tool
color 0B

:: Set environment variables to keep C: drive clean
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "GRADLE_USER_HOME=D:\.gradle"
set "PUB_CACHE=D:\.pub-cache"
set "PATH=D:\flutter\bin;%PATH%"

:menu
cls
echo ==========================================================
echo               LocalSync Flutter App Helper (LocalSync3)
echo ==========================================================
echo.
echo  C: Drive is Safe: All caches and downloads redirect to D:
echo.
echo  [1] Run App on Connected Device (flutter run)
echo  [2] Build + Install Debug APK on Phone
echo  [3] Build Release APK (flutter build apk --release)
echo  [4] Clean Build Cache (flutter clean)
echo  [5] Exit Helper
echo.
echo ==========================================================
echo.
set /p opt="Enter your choice (1-5): "

if "%opt%"=="1" goto run_app
if "%opt%"=="2" goto build_install
if "%opt%"=="3" goto build_release
if "%opt%"=="4" goto clean_cache
if "%opt%"=="5" goto exit_tool
echo.
echo [!] Invalid option, please enter 1 to 5.
pause
goto menu

:run_app
echo.
echo [*] Starting app on device...
call D:\flutter\bin\flutter.bat run
pause
goto menu

:build_install
echo.
echo [*] Building debug APK...
call D:\flutter\bin\flutter.bat build apk --debug
echo.
echo [*] Uninstalling old version from phone...
D:\AndroidFiles\Sdk\platform-tools\adb.exe uninstall com.example.localsync
echo.
echo [*] Installing new APK on phone...
D:\AndroidFiles\Sdk\platform-tools\adb.exe install "D:\AndroidFiles\Projects\LocalSync3\build\app\outputs\flutter-apk\app-debug.apk"
echo.
echo [*] Launching app...
D:\AndroidFiles\Sdk\platform-tools\adb.exe shell am start -n com.example.localsync/com.example.localsync.MainActivity
echo.
echo [*] Done! Check your phone screen.
pause
goto menu

:build_release
echo.
echo [*] Building release APK...
call D:\flutter\bin\flutter.bat build apk --release
echo.
echo [*] Release APK generated at:
echo D:\AndroidFiles\Projects\LocalSync3\build\app\outputs\flutter-apk\app-release.apk
pause
goto menu

:clean_cache
echo.
echo [*] Cleaning cache...
call D:\flutter\bin\flutter.bat clean
pause
goto menu

:exit_tool
exit
