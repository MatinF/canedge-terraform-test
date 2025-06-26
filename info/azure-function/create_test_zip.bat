@echo off
echo Creating minimal Azure Function deployment package...

REM Create a clean temp directory
if exist temp-deploy rmdir /S /Q temp-deploy
mkdir temp-deploy

REM Copy only essential files to the temp directory
echo Copying minimal function_app.py...
copy /Y function_app_minimal.py temp-deploy\function_app.py

echo Copying host.json...
copy /Y host.json temp-deploy\host.json

echo Copying requirements.txt...
copy /Y requirements.txt temp-deploy\requirements.txt

REM Create zip package with a timestamp
set timestamp=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set timestamp=%timestamp: =0%
echo Creating zip package: minimal-function-%timestamp%.zip

cd temp-deploy
powershell -Command "Compress-Archive -Path .\* -DestinationPath ..\minimal-function-%timestamp%.zip -Force"
cd ..

echo Deployment package created: minimal-function-%timestamp%.zip
echo.
echo Next steps:
echo 1. Upload this zip to your blob storage container
echo 2. Update the WEBSITE_RUN_FROM_PACKAGE setting to point to this zip
echo 3. Restart your function app

rmdir /S /Q temp-deploy
