@echo off
REM ===================================================================
REM  Compile MTF_Structure_Scalper_Runner_v2 from the command line.
REM  EDIT the two paths below to match your machine, then double-click.
REM ===================================================================
setlocal

REM --- 1) Folder where MetaEditor64.exe lives (your Exness MT5 install)
set "MT5DIR=C:\Program Files\Exness Technologies Ltd\MetaTrader 5"

REM --- 2) Your MT5 *data folder* MQL5 path
REM     (MT5 -> File -> Open Data Folder -> then \MQL5). Example:
set "MQL5DIR=%APPDATA%\MetaQuotes\Terminal\<YOUR_TERMINAL_HASH>\MQL5"

set "SRC=%MQL5DIR%\Experts\MTF_Structure_Scalper_Runner_v2\MTF_Structure_Scalper_Runner_v2_0.mq5"

if not exist "%MT5DIR%\metaeditor64.exe" (
  echo [ERROR] metaeditor64.exe not found at "%MT5DIR%".
  echo         Edit MT5DIR at the top of this file.
  pause & exit /b 1
)
if not exist "%SRC%" (
  echo [ERROR] Source not found: "%SRC%"
  echo         Copy the MTF_Structure_Scalper_Runner_v2 folder into %%MQL5DIR%%\Experts
  echo         and fix MQL5DIR at the top of this file.
  pause & exit /b 1
)

echo Compiling: "%SRC%"
"%MT5DIR%\metaeditor64.exe" /compile:"%SRC%" /log:"%~dp0compile.log"

echo.
echo ===================== COMPILE LOG =====================
type "%~dp0compile.log"
echo =======================================================
echo Target: 0 errors / 0 warnings. If any appear, send compile.log to Claude.
pause
