@echo off
setlocal enabledelayedexpansion

echo Starting zip file preparation...
echo.

:: Set output directory for zip files
set "OUTPUT_DIR=release"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

:: Read versions from the config file
set "VERSION_FILE=versions.cfg"
if not exist "%VERSION_FILE%" (
    echo Error: %VERSION_FILE% not found.
    exit /b 1
)

:: Initialize versions
set "AMAZON_VERSION="
set "GOOGLE_VERSION="
set "AZURE_VERSION="

:: Parse the versions.cfg file
for /f "tokens=1,2 delims==" %%a in (%VERSION_FILE%) do (
    if "%%a"=="amazon" set "AMAZON_VERSION=%%b"
    if "%%a"=="google" set "GOOGLE_VERSION=%%b"
    if "%%a"=="azure" set "AZURE_VERSION=%%b"
)

echo Detected versions:
echo Amazon: %AMAZON_VERSION%
echo Google: %GOOGLE_VERSION%
echo Azure:  %AZURE_VERSION%
echo.

:: Create a temporary directory for building the zip files
set "TEMP_DIR=temp_build"
if exist "%TEMP_DIR%" rd /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

:: ==========================================
:: Build Amazon Lambda zip
:: ==========================================
echo Building Amazon Lambda zip file...
set "AMAZON_BUILD_DIR=%TEMP_DIR%\amazon"
mkdir "%AMAZON_BUILD_DIR%"
mkdir "%AMAZON_BUILD_DIR%\modules"

:: Copy files for Amazon Lambda
copy lambda_function.py "%AMAZON_BUILD_DIR%\"
copy mdf2parquet_decode "%AMAZON_BUILD_DIR%\"
xcopy /E /I /Y modules "%AMAZON_BUILD_DIR%\modules"

:: Create the zip file
set "AMAZON_ZIP_NAME=mdf-to-parquet-amazon-function-v%AMAZON_VERSION%.zip"
cd "%AMAZON_BUILD_DIR%"
powershell Compress-Archive -Path * -DestinationPath "..\..\%OUTPUT_DIR%\%AMAZON_ZIP_NAME%" -Force
cd ..\..
echo Amazon Lambda zip created: %OUTPUT_DIR%\%AMAZON_ZIP_NAME%
echo.

:: ==========================================
:: Build Google Cloud Function zip
:: ==========================================
echo Building Google Cloud Function zip file...
set "GOOGLE_BUILD_DIR=%TEMP_DIR%\google"
mkdir "%GOOGLE_BUILD_DIR%"
mkdir "%GOOGLE_BUILD_DIR%\modules"

:: Copy files for Google Cloud Function
copy main.py "%GOOGLE_BUILD_DIR%\"
copy mdf2parquet_decode "%GOOGLE_BUILD_DIR%\"
if exist requirements.txt copy requirements.txt "%GOOGLE_BUILD_DIR%\"
xcopy /E /I /Y modules "%GOOGLE_BUILD_DIR%\modules"

:: Create the zip file
set "GOOGLE_ZIP_NAME=mdf-to-parquet-google-function-v%GOOGLE_VERSION%.zip"
cd "%GOOGLE_BUILD_DIR%"
powershell Compress-Archive -Path * -DestinationPath "..\..\%OUTPUT_DIR%\%GOOGLE_ZIP_NAME%" -Force
cd ..\..
echo Google Cloud Function zip created: %OUTPUT_DIR%\%GOOGLE_ZIP_NAME%
echo.

:: ==========================================
:: Build Azure Function zip
:: ==========================================
echo Building Azure Function zip file...
set "AZURE_BUILD_DIR=%TEMP_DIR%\azure"
mkdir "%AZURE_BUILD_DIR%"
mkdir "%AZURE_BUILD_DIR%\modules"

:: Copy files for Azure Function
copy function_app.py "%AZURE_BUILD_DIR%\"
copy mdf2parquet_decode "%AZURE_BUILD_DIR%\"
xcopy /E /I /Y modules "%AZURE_BUILD_DIR%\modules"

:: Create the zip file
set "AZURE_ZIP_NAME=mdf-to-parquet-azure-function-v%AZURE_VERSION%.zip"
cd "%AZURE_BUILD_DIR%"
powershell Compress-Archive -Path * -DestinationPath "..\..\%OUTPUT_DIR%\%AZURE_ZIP_NAME%" -Force
cd ..\..
echo Azure Function zip created: %OUTPUT_DIR%\%AZURE_ZIP_NAME%
echo.

:: Clean up
rd /s /q "%TEMP_DIR%"

echo All zip files have been created successfully in the %OUTPUT_DIR% directory.
echo.

:: List created files
echo Created files:
dir /b "%OUTPUT_DIR%\mdf-to-parquet-*.zip"
echo.

endlocal
