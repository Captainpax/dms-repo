@echo off
setlocal

:: Simple helper to push a Docker image to Docker Hub.
echo ============================================
echo   DarkMatterServers Docker Hub Uploader
echo ============================================

set "IMAGE_NAME="
set /p IMAGE_NAME="Enter the full image name (e.g., username/repo:tag) to push: "
if "%IMAGE_NAME%"=="" (
    echo No image specified. Exiting.
    exit /b 1
)

echo Checking Docker daemon status...
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker does not appear to be running or is not accessible.
    echo Please start Docker Desktop and try again.
    exit /b 1
)

call :ensure_login
if errorlevel 1 (
    echo Login failed or aborted. Exiting.
    exit /b 1
)

echo Pushing %IMAGE_NAME% to Docker Hub...
docker push "%IMAGE_NAME%"
if errorlevel 1 (
    echo Docker push failed. Please review the error above.
    exit /b 1
)

echo Docker image pushed successfully.
exit /b 0

:ensure_login
set "DOCKER_USER="
for /f "tokens=1,* delims=:" %%A in ('docker info 2^>NUL ^| findstr /B /C:"Username:"') do set "DOCKER_USER=%%B"

:: Trim leading spaces if any
if defined DOCKER_USER set "DOCKER_USER=%DOCKER_USER:~1%"

if not defined DOCKER_USER goto :login
if /I "%DOCKER_USER%"=="(not logged in)" goto :login

echo Already logged in as %DOCKER_USER%.
exit /b 0

:login
echo No Docker Hub login detected. Please sign in.
docker login
exit /b %ERRORLEVEL%
