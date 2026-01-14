@echo off
chcp 65001 >nul

:: 检查是否以管理员权限运行
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo ⚠️  需要管理员权限才能安装 Windows 服务。
    echo 正在请求提权...
    echo.

    :: 重新以管理员身份启动当前批处理文件
    powershell.exe -Command ^
        "Start-Process -FilePath 'cmd' -ArgumentList '/c', '\"%~f0\"' -Verb RunAs"
    
    exit /b
)

:: 获取当前批处理文件所在目录
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

title llama.cpp 部署工具启动器

echo.
echo 正在启动 llama.cpp 部署工具...
echo.

:: 临时绕过 PowerShell 执行策略，仅对本次会话生效
powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_DIR%deploy_llama_single.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ 脚本执行失败或被终止。
) else (
    echo.
    echo ✅ 脚本已正常退出。
)

pause