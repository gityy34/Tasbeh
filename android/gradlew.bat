@echo off
where gradle >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  gradle %*
  exit /b %ERRORLEVEL%
)
echo Gradle is not installed. Install Flutter and Android tooling, then run: flutter build apk --release 1>&2
exit /b 1

