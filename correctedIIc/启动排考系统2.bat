@echo off
setlocal enabledelayedexpansion
chcp 936 >nul

:: 设置变量
set "SCRIPT_NAME=code5_ExaminationRoomAllocation.m"
set "TARGET_PATH=%~dp0%SCRIPT_NAME%"
set "MATLAB_EXE=D:\Software\Matlab\bin\matlab.exe"
set "SHORTCUT_PATH=%USERPROFILE%\Desktop\考场编排系统.lnk"

:: 创建快捷方式命令
set "PS_CMD=$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%SHORTCUT_PATH%');"
set "PS_CMD=%PS_CMD% $s.TargetPath='%MATLAB_EXE%';"
:: 关键修复：这里的 run 命令加上完整的路径引用
set "PS_CMD=%PS_CMD% $s.Arguments='-nosplash -nodesktop -r \"\"run(''%TARGET_PATH%'')\"\"';"
set "PS_CMD=%PS_CMD% $s.WorkingDirectory='%~dp0';"
set "PS_CMD=%PS_CMD% $s.IconLocation='%MATLAB_EXE%';"
set "PS_CMD=%PS_CMD% $s.Save()"

powershell -NoProfile -ExecutionPolicy Bypass -Command "%PS_CMD%"

echo [完成] 快捷方式已更新，请尝试通过桌面图标启动。
pause