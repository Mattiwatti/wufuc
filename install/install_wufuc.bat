@echo off
title wufuc installer - v0.6
:: Copyright (C) 2017 zeffy

:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.

:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.

:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.

echo Copyright (C) 2017 zeffy
echo This program comes with ABSOLUTELY NO WARRANTY.
echo This is free software, and you are welcome to redistribute it
echo under certain conditions; see COPYING.txt for details.
echo.

fltmc >nul 2>&1 || (
    echo This batch script requires administrator privileges. Right-click on
    echo %~nx0 and select "Run as administrator".
    goto :die
)

echo Checking system requirements...

if /I "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    goto :is_x64
) else (
    if /I "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
        goto :is_x64
    )
    if /I "%PROCESSOR_ARCHITECTURE%"=="x86" (
        set "WINDOWS_ARCHITECTURE=x86"
        set "wufuc_dll=%~dp0wufuc32.dll"
        goto :check_ver
    )
)
goto :unsupported_os

:is_x64
set "WINDOWS_ARCHITECTURE=x64"
set "wufuc_dll=%~dp0wufuc64.dll"

:check_ver
wmic /output:stdout os get version | findstr "^6\.1\." >nul && (
    set "WINDOWS_VER=6.1"
    set "SUPPORTED_HOTFIXES=KB4019265 KB4019264 KB4015552 KB4015549 KB4015546 KB4012218"
    echo Detected supported operating system: Windows 7 %WINDOWS_ARCHITECTURE%
    goto :check_hotfix
)
wmic /output:stdout os get version | findstr "^6\.3\." >nul && (
    set "WINDOWS_VER=8.1"
    set "SUPPORTED_HOTFIXES=KB4019217 KB4019215 KB4015553 KB4015550 KB4015547 KB4012219"
    echo Detected supported operating system: Windows 8.1 %WINDOWS_ARCHITECTURE%
    goto :check_hotfix
)

:unsupported_os
echo Detected that you are using an unsupported operating system.
echo.
echo This patch only works on the following versions of Windows:
echo.
echo - Windows 7 (x64 and x86)
echo - Windows 8.1 (x64 and x86)
echo - Windows Server 2008 R2
echo - Windows Server 2012 R2
goto :die

:check_hotfix
for %%a in (%SUPPORTED_HOTFIXES%) do (
    wmic /output:stdout qfe get hotfixid | find "%%a" >nul && (
        set "INSTALLED_HOTFIX=%%a"
        echo Detected installed supported update: %%a
        goto :confirmation
    )
)

echo.
echo WARNING - Detected that no supported updates are installed! 
echo.
echo This can be a false warning, if you are certain that need wufuc then you
echo can continue (there will be no side effects even if you don't need it)

set /p CONTINUE=Enter 'Y' if you still want to continue: 
if /I not "%CONTINUE%"=="Y" goto :cancel

:confirmation
echo.
echo wufuc disables the "Unsupported Hardware" message in Windows Update, 
echo and allows you to continue installing updates on Windows 7 and 8.1
echo systems with Intel Kaby Lake, AMD Ryzen, or other unsupported processors.
echo.

set /p CONTINUE=Enter 'Y' if you want to install wufuc: 
if /I not "%CONTINUE%"=="Y" goto :cancel
echo.

set "vcredist_path=%~dp0_Redist\vcredist_%WINDOWS_ARCHITECTURE%.exe"
if exist "%vcredist_path%" (
    echo Installing Microsoft Visual C^+^+ 2017 Redistributable ^(%WINDOWS_ARCHITECTURE%^)...
    "%vcredist_path%" /passive /norestart
    goto :install
)

echo Couldn't locate and install Microsoft Visual C^+^+ 2017 Redistributable ^(%WINDOWS_ARCHITECTURE%^).

set /p CONTINUE=Enter 'Y' if you still want to continue: 
if /I not "%CONTINUE%"=="Y" goto :cancel
echo.

:install
set "wufuc_task=wufuc.{72EEE38B-9997-42BD-85D3-2DD96DA17307}"
schtasks /Create /XML "%~dp0wufuc.xml" /TN "%wufuc_task%" /F
schtasks /Change /TN "%wufuc_task%" /TR "'%systemroot%\system32\rundll32.exe' """%wufuc_dll%""",Rundll32Entry"
schtasks /Change /TN "%wufuc_task%" /ENABLE
rundll32 "%wufuc_dll%",Rundll32Unload
schtasks /Run /TN "%wufuc_task%"

echo.
echo Installed and started wufuc!
goto :die

:die
echo.
echo Press any key to exit...
pause >nul
exit

:cancel
echo.
echo Canceled by user, press any key to exit...
pause >nul
exit
