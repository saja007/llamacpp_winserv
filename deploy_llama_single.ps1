# deploy_llama_single.ps1 (v2 - 支持自定义服务名)
# 功能：单模型部署 + 端口占用检测 + 自定义服务名 + 测试运行/安装服务

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 使用绝对路径 ?
$serverExe = Join-Path $PSScriptRoot "llama-server.exe"

if (-not (Test-Path $serverExe)) {
    Write-Host "? 错误：未找到 llama-server.exe" -ForegroundColor Red
    Write-Host "请将此脚本放在 llama.cpp 的 bin 目录中。" -ForegroundColor Yellow
    Write-Host "当前检测路径: $serverExe" -ForegroundColor Gray
    Read-Host "按回车退出..."
    exit 1
}

Write-Host "?? llama.cpp 单模型部署工具（支持自定义服务名）" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray

# === 1. 选择模型文件 ===
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory = $PSScriptRoot
$dialog.Filter = "GGUF 模型 (*.gguf)|*.gguf|所有文件 (*.*)|*.*"
$dialog.Title = "请选择 Qwen3 Embedding 或 Reranker 模型 (GGUF 格式)"

if ($dialog.ShowDialog() -ne 'OK') {
    Write-Host "?? 未选择模型，退出。" -ForegroundColor Yellow
    exit 0
}

$modelPath = $dialog.FileName
$modelName = [IO.Path]::GetFileNameWithoutExtension($modelPath)
Write-Host "? 已选择模型: $modelName.gguf" -ForegroundColor Green


# === 2. 输入端口并检测占用 ===
do {
    $portStr = Read-Host "请输入服务端口 (默认 8080)"
    if ([string]::IsNullOrWhiteSpace($portStr)) { $portStr = "8080" }
    
    if (-not ($portStr -match '^\d+$')) {
        Write-Host "? 端口必须是数字，请重新输入。" -ForegroundColor Red
        continue
    }

    $port = [int]$portStr
    if ($port -lt 1 -or $port -gt 65535) {
        Write-Host "? 端口范围应在 1-65535。" -ForegroundColor Red
        continue
    }

    # 检测端口是否被占用
    $listening = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Where-Object State -eq Listen
    if ($listening) {
        $processId = $listening.OwningProcess
        $processName = (Get-Process -Id $processId -ErrorAction SilentlyContinue).ProcessName
        Write-Host "? 端口 $port 已被占用！进程: $processName (PID: $processId)" -ForegroundColor Red
        $retry = Read-Host "是否换一个端口？(Y/n)"
        if ($retry -eq 'n' -or $retry -eq 'N') {
            Write-Host "退出部署。" -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Host "? 端口 $port 可用。" -ForegroundColor Green
        break
    }
} while ($true)

# === 3. 构建命令参数 ===
$arguments = @("-m", $modelPath, "--port", $port, "--embedding")
$fullCmd = "$serverExe " + ($arguments -join " ")

Write-Host "`n?? 启动命令预览：" -ForegroundColor Cyan
Write-Host $fullCmd -ForegroundColor Gray

# === 4. 用户选择操作模式 ===
Write-Host "`n请选择操作模式：" -ForegroundColor Green
Write-Host "1 → ?? 测试运行（前台运行，按 Ctrl+C 停止）"
Write-Host "2 → ??  安装为 Windows 服务（需管理员权限）"
Write-Host "其他键 → 退出"

$mode = Read-Host "输入选项"

switch ($mode) {
    "1" {
        Write-Host "`n?? 正在启动测试服务..." -ForegroundColor Cyan
        Write-Host "访问 http://localhost:$port/docs 查看 API 文档" -ForegroundColor Yellow
        Write-Host "按 Ctrl+C 停止服务。`n" -ForegroundColor Gray
        try {
            & $serverExe $arguments
        } catch {
            Write-Host "?? 启动失败: $_" -ForegroundColor Red
        }
    }

    "2" {
        # 检查管理员权限
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Write-Host "`n? 安装服务需要管理员权限！" -ForegroundColor Red
            Write-Host "请右键 PowerShell → '以管理员身份运行' 此脚本。" -ForegroundColor Yellow
            Read-Host "按回车退出..."
            exit 1
        }

        # === 新增：自定义服务名 ===
        Write-Host "`n?? 请输入服务名称（用于 Windows 服务管理器）" -ForegroundColor Cyan
        Write-Host "提示：只能包含字母、数字、下划线，长度 1-24 个字符。" -ForegroundColor Gray
        $defaultServiceName = "llama_" + ($modelName -replace '[^a-zA-Z0-9_]', '_').Substring(0, 18)
        $serviceNameInput = Read-Host "服务名 (默认: $defaultServiceName)"

        if ([string]::IsNullOrWhiteSpace($serviceNameInput)) {
            $serviceName = $defaultServiceName
        } else {
            $serviceName = $serviceNameInput.Trim()
        }

        # 校验服务名合法性
        if ($serviceName -notmatch '^[a-zA-Z][a-zA-Z0-9_]{0,23}$') {
            Write-Host "? 服务名格式不合法！必须以字母开头，仅含字母/数字/下划线，长度 1-24。" -ForegroundColor Red
            $serviceName = $defaultServiceName
            Write-Host "已自动使用默认名称: $serviceName" -ForegroundColor Yellow
        }

        Write-Host "? 最终服务名: $serviceName" -ForegroundColor Green

        # 尝试使用内置或系统 nssm
        $nssm = if (Test-Path ".\nssm.exe") { ".\nssm.exe" } else { "nssm" }

        # 获取 bin 目录的绝对路径（即 llama-server.exe 所在目录）
        $binDir = $PSScriptRoot

        try {
            # 安装服务并设置工作目录
            & $nssm install $serviceName $serverExe $arguments | Out-Null
            & $nssm set $serviceName AppDirectory $binDir | Out-Null   # ?? 关键！设置工作目录
            & $nssm set $serviceName Start SERVICE_AUTO_START | Out-Null
            & $nssm start $serviceName | Out-Null

            Write-Host "`n? 服务 '$serviceName' 安装并启动成功！" -ForegroundColor Green
            Write-Host "服务将在系统开机时自动运行。"
            Write-Host "管理路径：Win+R → services.msc → 搜索 '$serviceName'" -ForegroundColor Gray
        } catch {
            Write-Host "`n?? 安装失败: $_" -ForegroundColor Red
            Write-Host "请确认已安装 NSSM 并配置到 PATH，或在 bin 目录放置 nssm.exe。"
        }
    }

    default {
        Write-Host "已取消操作。" -ForegroundColor Yellow
    }
}

Read-Host "`n按回车退出..."