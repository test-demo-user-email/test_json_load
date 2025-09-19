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

REM 2. Build project with trunk (creates dist folder)
echo Building project with trunk...
trunk build --release --public-url ./
if %errorlevel% neq 0 (
    echo ERROR: Trunk build failed
    goto :error
)
echo Build complete!

REM 3. Store current commit hash for reference
for /f %%i in ('git rev-parse HEAD') do set COMMIT_HASH=%%i

REM 4. Delete existing gh-pages branch (local and remote)
echo Removing existing gh-pages branch...
git branch -D gh-pages 2>nul || echo No local gh-pages branch to delete
git push origin --delete gh-pages 2>nul || echo No remote gh-pages branch to delete

REM 5. Create clean orphan gh-pages branch
echo Creating clean gh-pages branch...
git checkout --orphan gh-pages
if %errorlevel% neq 0 (
    echo ERROR: Failed to create gh-pages branch
    goto :error
)

REM 6. Clear the git index (orphan branch starts with all files staged)
echo Clearing git index...
git reset >nul 2>&1 || echo Index already clear

REM 7. Copy files from dist to root of gh-pages
echo Copying built files to root...
if exist dist (
    xcopy /e /y dist\* . >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Failed to copy files from dist
        goto :error
    )
    echo Built files copied to root
) else (
    echo ERROR: Dist directory not found
    goto :error
)

REM 8. Copy static folder if it exists (from main branch)
echo Copying static folder...
git checkout main -- static 2>nul
if %errorlevel% equ 0 (
    echo Static folder copied successfully
) else (
    echo No static folder found in main branch
)

REM 9. Add and commit all files to gh-pages
echo Committing to gh-pages...
git add .
git commit -m "Deploy to GitHub Pages from %COMMIT_HASH:~0,7% - %date% %time%"
if %errorlevel% neq 0 (
    echo ERROR: Failed to commit to gh-pages
    goto :error
)

REM 10. Push the new gh-pages branch
echo Pushing gh-pages branch...
git push origin gh-pages
if %errorlevel% neq 0 (
    echo ERROR: Failed to push gh-pages branch
    goto :error
)

REM 11. Switch back to main branch
echo Switching back to main...
git checkout main
if %errorlevel% neq 0 (
    echo ERROR: Failed to return to main branch
    goto :error
)

REM 12. Clean up dist folder from main branch
echo Cleaning up dist folder from main...
if exist dist (
    rmdir /s /q dist
    echo Dist folder removed from main branch
)

echo.
echo ✅ Deployment complete!
echo.
echo Main branch: Contains all your source files (tomls, src, etc.)
echo gh-pages branch: Contains only built files in root + static folder
echo.
echo Your site should be available at: https://[username].github.io/[repository-name]
echo.
goto :end

:error
echo.
echo ❌ Deployment failed!
echo Switching back to main branch...
git checkout main >nul 2>&1
echo Please check the error messages above and try again.
echo.
exit /b 1

:end
ENDLOCAL
pause