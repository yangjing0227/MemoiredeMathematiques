@echo off
title Exam Scheduler Launcher
echo --------------------------------------------------
echo Initializing MATLAB environment, please wait...
echo Current Directory: %~dp0
echo --------------------------------------------------

:: 1. 使用你提供的 D 盘路径 (自动补全了 \bin\matlab.exe)
set MATLAB_PATH="D:\Software\Matlab\bin\matlab.exe"

:: 2. 自动获取当前文件夹并运行脚本
:: 注意：这里使用了引号嵌套保护，确保路径中有空格也能运行
%MATLAB_PATH% -nosplash -nodesktop -r "addpath('%~dp0'); run('code4_AutoExamSceduler.m');"

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Cannot find MATLAB at D:\Software\Matlab\bin\matlab.exe
    echo Please check if the file exists in that folder.
)

echo.
echo If the program finished, you can close this window.
pause