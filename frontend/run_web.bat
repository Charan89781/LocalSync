@echo off
title LocalSync Web Server
color 0E

:: Set environment variables
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "GRADLE_USER_HOME=D:\.gradle"
set "PUB_CACHE=D:\.pub-cache"
set "PATH=D:\flutter\bin;%PATH%"

echo ==========================================================
echo              Starting LocalSync Flutter Web Server
echo ==========================================================
echo.
echo Launching the application on the local web-server.
echo It will remain active as long as this window is open.
echo.
echo Running on port 8080...
echo You can access it at: http://localhost:8080
echo ==========================================================
echo.

call flutter run -d web-server --release --web-port 8080 --web-hostname 0.0.0.0
pause
