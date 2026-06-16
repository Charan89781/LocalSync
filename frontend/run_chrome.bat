@echo off
title LocalSync Web Debug (Chrome)
color 0B

:: Set environment variables
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "GRADLE_USER_HOME=D:\.gradle"
set "PUB_CACHE=D:\.pub-cache"
set "PATH=D:\flutter\bin;%PATH%"

echo ==========================================================
echo           Starting LocalSync Flutter Web in Chrome
echo ==========================================================
echo.
echo Launching the application in Chrome debug mode.
echo.

call flutter run -d chrome
pause
