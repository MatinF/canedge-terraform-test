@echo off
REM Script to create a properly structured Azure Functions ZIP package
echo Creating function ZIP package...

REM Configuration
set SOURCE_DIR=%~dp0updated-azure-function
set OUTPUT_ZIP=%SOURCE_DIR%\function-deploy-package.zip

REM Remove existing ZIP if it exists
if exist "%OUTPUT_ZIP%" del "%OUTPUT_ZIP%"

REM Create temporary directory for ZIP creation
set TEMP_DIR=%SOURCE_DIR%\temp_deploy
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

REM Copy all required files except ZIP files
echo Copying function files...
xcopy "%SOURCE_DIR%\*.py" "%TEMP_DIR%\" /Y
xcopy "%SOURCE_DIR%\*.json" "%TEMP_DIR%\" /Y
xcopy "%SOURCE_DIR%\requirements.txt" "%TEMP_DIR%\" /Y
xcopy "%SOURCE_DIR%\.deployment" "%TEMP_DIR%\" /Y
if exist "%SOURCE_DIR%\modules" (
    xcopy "%SOURCE_DIR%\modules" "%TEMP_DIR%\modules\" /E /I /Y
)
if exist "%SOURCE_DIR%\mdf2parquet_decode" (
    xcopy "%SOURCE_DIR%\mdf2parquet_decode" "%TEMP_DIR%\mdf2parquet_decode\" /E /I /Y
)

REM Create ZIP file
echo Creating ZIP archive...
powershell -command "Compress-Archive -Path '%TEMP_DIR%\*' -DestinationPath '%OUTPUT_ZIP%' -Force"

REM Clean up temporary directory
rmdir /s /q "%TEMP_DIR%"

echo Done! Created: %OUTPUT_ZIP%
echo.
echo Upload this ZIP file to your Azure Storage container and update
echo the 'function_zip_name' variable in your Terraform deployment script.
