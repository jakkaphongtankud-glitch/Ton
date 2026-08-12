@echo off
REM ===================================================================
REM  Run the Strategy Tester headless using backtest.ini
REM  EDIT MT5DIR to your Exness MT5 install, then double-click.
REM ===================================================================
setlocal

set "MT5DIR=C:\Program Files\Exness Technologies Ltd\MetaTrader 5"

if not exist "%MT5DIR%\terminal64.exe" (
  echo [ERROR] terminal64.exe not found at "%MT5DIR%".
  echo         Edit MT5DIR at the top of this file.
  pause & exit /b 1
)

echo Starting Strategy Tester with backtest.ini ...
echo (First real-tick run downloads XAUUSDm tick history - can take a while.)
"%MT5DIR%\terminal64.exe" /config:"%~dp0backtest.ini"

echo.
echo Done. The report (MTSR2_report.html) is written in the MT5 install folder.
echo Reminder: builds 01-06 place no trades, so 0 trades is EXPECTED for now.
pause
