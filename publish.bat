@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

echo Starting GitHub Pages deployment...

REM 1. Ensure we're on main branch
echo Checking out main branch...
git checkout main
if %errorlevel% neq 0 (
    echo ERROR: Failed to checkout main branch
    goto :error
)

REM 2. Build project with trunk
echo Building project with trunk...
trunk build --release --public-url ./
if %errorlevel% neq 0 (
    echo ERROR: Trunk build failed
    goto :error
)
echo Build complete!

REM 3. Create/recreate gh-pages branch as duplicate of main
echo Creating gh-pages branch from main...
git branch -D gh-pages 2>nul || echo gh-pages branch didn't exist
git checkout -b gh-pages
if %errorlevel% neq 0 (
    echo ERROR: Failed to create gh-pages branch
    goto :error
)

REM 4. Go back to main and delete dist directory
echo Switching to main to clean up dist...
git checkout main
if %errorlevel% neq 0 (
    echo ERROR: Failed to checkout main branch
    goto :error
)

if exist dist (
    rmdir /s /q dist
    echo Dist directory removed from main
)

REM 5. Go back to gh-pages
echo Switching to gh-pages...
git checkout gh-pages
if %errorlevel% neq 0 (
    echo ERROR: Failed to checkout gh-pages branch
    goto :error
)

REM 6. Delete all files except dist and static directories
echo Cleaning gh-pages branch (keeping only dist and static)...
for /f "delims=" %%i in ('dir /b /a-d 2^>nul') do (
    if /i not "%%i"=="dist" if /i not "%%i"=="static" (
        del "%%i" 2>nul
    )
)

for /f "delims=" %%i in ('dir /b /ad 2^>nul') do (
    if /i not "%%i"=="dist" if /i not "%%i"=="static" if /i not "%%i"==".git" (
        rmdir /s /q "%%i" 2>nul
    )
)

REM 7. Copy all files from dist to root
echo Copying files from dist to root...
if exist dist (
    xcopy /e /y dist\* . >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Failed to copy files from dist
        goto :error
    )
    echo Files copied from dist to root
) else (
    echo ERROR: Dist directory not found
    goto :error
)

REM 8. Delete dist directory
echo Removing dist directory...
rmdir /s /q dist
echo Dist directory removed

REM 9. Commit changes to gh-pages
echo Committing changes to gh-pages...
git add .
git commit -m "Deploy to GitHub Pages - %date% %time%"
if %errorlevel% neq 0 (
    echo WARNING: Nothing new to commit
) else (
    echo Pushing to gh-pages...
    git push origin gh-pages --force
    if %errorlevel% neq 0 (
        echo ERROR: Failed to push to gh-pages
        goto :error
    )
)

REM 10. Go back to main
echo Switching back to main...
git checkout main
if %errorlevel% neq 0 (
    echo ERROR: Failed to return to main branch
    goto :error
)

echo.
echo ✅ Deployment complete!
echo Your site should be available at: https://[username].github.io/[repository-name]
echo.
goto :end

:error
echo.
echo ❌ Deployment failed!
echo Please check the error messages above and try again.
echo.
exit /b 1

:end
ENDLOCAL
pause