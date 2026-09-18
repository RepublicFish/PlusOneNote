@echo off
chcp 65001 >nul
setlocal

REM ============================================================
REM  kamanotes - one click start (backend + frontend)
REM  Prerequisite: MySQL(3306) and Redis(6379) must be running.
REM ============================================================

set "ROOT=%~dp0"
set "JAVA=D:\dev\jdk21\bin\java.exe"
set "JAR=%ROOT%backend\target\notes-0.0.1.jar"

echo ============================================================
echo   kamanotes start
echo ============================================================
echo.

if not exist "%JAVA%" (
  echo [ERROR] Java not found: %JAVA%
  echo         Edit the JAVA variable in this script.
  pause
  exit /b 1
)

if not exist "%JAR%" (
  echo [ERROR] Backend jar not found: %JAR%
  echo         Build it first:  cd backend ^&^& mvn -DskipTests package
  pause
  exit /b 1
)

echo [1/2] Starting backend on port 8081 ...
start "kamanotes-backend" cmd /k "cd /d "%ROOT%backend" && "%JAVA%" -jar target\notes-0.0.1.jar --spring.datasource.password=root --server.port=8081"

echo       waiting for backend to boot ...
timeout /t 25 /nobreak >nul

echo [2/2] Starting frontend on port 5173 ...
start "kamanotes-frontend" cmd /k "cd /d "%ROOT%frontend" && npm run dev"

echo.
echo ============================================================
echo   Backend : http://127.0.0.1:8081
echo   Frontend: http://localhost:5173
echo ============================================================
echo.
echo Two new windows were opened and will keep the services alive.
echo Close those windows to stop the services.
echo.
pause
