#!/usr/bin/env pwsh

# Exit on error, undefined variable, or error in pipeline
$ErrorActionPreference = "Stop"

# ----- Constants -----
$SCRIPT_NAME = (Get-Item $PSCommandPath).Name
$DOWNLOAD_URL_PREFIX = "https://raw.githubusercontent.com/liukunup/HomeLab/refs/heads/main/applications/Dev"
$PROJECT_DIR = "awesome-dev-stack"

# Colors for output
$RED = "`e[0;31m"
$GREEN = "`e[0;32m"
$YELLOW = "`e[1;33m"
$BLUE = "`e[0;34m"
$NC = "`e[0m" # No Color

# ----- Functions -----
# Show help message
function Show-Help {
    @"
Usage: $SCRIPT_NAME [options] 

Options:
  --prepare           准备环境
  --deploy=<service>  部署指定服务

  # 默认指令
  -h, --help          显示帮助信息

Examples:
  $SCRIPT_NAME --prepare      # 准备环境
  $SCRIPT_NAME --deploy=all   # 部署所有服务
  $SCRIPT_NAME --deploy=mysql # 只部署 MySQL 服务
"@
}

# Check if required commands are available
function Check-Dependencies {
    $dependencies = @("docker", "docker-compose")

    foreach ($cmd in $dependencies) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Host "${RED}Error: please install $cmd first.${NC}" -ForegroundColor Red
            exit 1
        }
    }
}

# Get the host machine's IP address
function Get-HostIP {
    try {
        # Try to get the first non-loopback IPv4 address
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
            $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' 
        } | Sort-Object InterfaceIndex | Select-Object -First 1).IPAddress
        
        if ($ip) {
            return $ip
        }
    }
    catch {
        # Fallback if the above fails
        try {
            $ip = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString
            if ($ip) { return $ip }
        }
        catch {
            # Final fallback
            return "127.0.0.1"
        }
    }
    
    return "127.0.0.1"
}

# Enhanced password generator
function Generate-RandomPassword {
    param(
        [int]$Length = 16,
        [string]$CharTypes = "lud",  # 默认包含小写、大写、数字
        [string]$CustomChars = ""
    )

    $lowercase = "abcdefghijklmnopqrstuvwxyz"
    $uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $digits = "0123456789"
    $special = "!@#$%^&*()_+-=[]{}|;:,.<>?~"

    $charPool = ""

    if ($CustomChars) {
        $charPool = $CustomChars
    }
    else {
        if ($CharTypes -contains "l") { $charPool += $lowercase }
        if ($CharTypes -contains "u") { $charPool += $uppercase }
        if ($CharTypes -contains "d") { $charPool += $digits }
        if ($CharTypes -contains "s") { $charPool += $special }

        if ([string]::IsNullOrEmpty($charPool)) {
            $charPool = $lowercase + $uppercase + $digits
        }
    }

    if ([string]::IsNullOrEmpty($charPool)) {
        Write-Error "Error: Character pool is empty."
        return $null
    }

    $password = -join ((1..$Length) | ForEach-Object {
        $charPool[(Get-Random -Maximum $charPool.Length)]
    })
    
    return $password
}

# Prepare environment: check dependencies, create project dir, download files, setup .env
function Prepare-Environment {
    Write-Host "${BLUE}🚀 准备环境...${NC}" -ForegroundColor Blue

    Write-Host "${BLUE}🔍 检查依赖...${NC}" -ForegroundColor Blue
    Check-Dependencies

    Write-Host "${BLUE}📁 创建目录...${NC}" -ForegroundColor Blue
    if (-not (Test-Path $PROJECT_DIR)) {
        New-Item -ItemType Directory -Path $PROJECT_DIR -Force | Out-Null
    }
    Set-Location $PROJECT_DIR

    Write-Host "${BLUE}⬇️ 下载 .env.example ...${NC}" -ForegroundColor Blue
    if (-not (Test-Path "$PROJECT_DIR/.env.example")) {
        Invoke-WebRequest -Uri "${DOWNLOAD_URL_PREFIX}/.env.example" -OutFile ".env.example"
    }

    Write-Host "${BLUE}⬇️ 下载 docker-compose.yml ...${NC}" -ForegroundColor Blue
    if (-not (Test-Path "$PROJECT_DIR/docker-compose.yml")) {
        Invoke-WebRequest -Uri "${DOWNLOAD_URL_PREFIX}/docker-compose.yml" -OutFile "docker-compose.yml"
    }

    if ((Test-Path ".env.example") -and (-not (Test-Path ".env"))) {
        Setup-Environment
    }
    elseif (Test-Path ".env") {
        Write-Host "${GREEN}✅ .env 文件已存在${NC}" -ForegroundColor Green
    }
    else {
        Write-Host "${RED}❌ .env.example 文件不存在${NC}" -ForegroundColor Red
        exit 1
    }
}

# Setup .env file with dynamic values
function Setup-Environment {
    Write-Host "${BLUE}📝 创建 .env 环境变量文件...${NC}" -ForegroundColor Blue
    Copy-Item .env.example .env

    $HOST_IP = Get-HostIP
    Write-Host "${GREEN}✅ 检测到本机IP: ${HOST_IP}${NC}" -ForegroundColor Green
    
    $envContent = Get-Content .env
    if ($envContent -match "HOST_IP=") {
        $envContent = $envContent -replace "HOST_IP=.*", "HOST_IP=${HOST_IP}"
        $envContent | Set-Content .env
        Write-Host "${GREEN}✅ 已更新HOST_IP为: ${HOST_IP}${NC}" -ForegroundColor Green
    }

    $passwordFields = @(
        "MYSQL_ROOT_PASSWORD"
        "MYSQL_PASSWORD"
        "REDIS_PASSWORD"
        "MINIO_ROOT_PASSWORD"
        "GRAFANA_ADMIN_PASSWORD"
        "INFLUXDB_ADMIN_PASSWORD"
        "CLICKHOUSE_PASSWORD"
    )
    
    $envContent = Get-Content .env
    foreach ($field in $passwordFields) {
        if ($envContent -match "${field}=") {
            $randPassword = Generate-RandomPassword -Length 16 -CharTypes "lud"
            $envContent = $envContent -replace "${field}=.*", "${field}=${randPassword}"
            Write-Host "${GREEN}✅ 已生成随机密码 for ${field}${NC}" -ForegroundColor Green
        }
    }
    $envContent | Set-Content .env

    $secretFields = @(
        "INFLUXDB_TOKEN"
        "APISIX_API_KEY"
    )
    
    $envContent = Get-Content .env
    foreach ($field in $secretFields) {
        if ($envContent -match "${field}=") {
            $randSecret = Generate-RandomPassword -Length 32 -CharTypes "ld"
            $envContent = $envContent -replace "${field}=.*", "${field}=${randSecret}"
            Write-Host "${GREEN}✅ 已生成随机密钥 for ${field}${NC}" -ForegroundColor Green
        }
    }
    $envContent | Set-Content .env

    Write-Host "${GREEN}✅ 配置文件已创建: .env${NC}" -ForegroundColor Green
    Write-Host "${YELLOW}⚠️ 请检查并根据需要修改 .env 文件中的配置项${NC}" -ForegroundColor Yellow
}

# Deploy service(s) using Docker Compose
function Deploy-Service {
    param(
        [string]$Service = "all"
    )

    Write-Host "${BLUE}🐳 部署服务: ${Service}...${NC}" -ForegroundColor Blue

    Write-Host "${BLUE}⬇️ 拉取镜像...${NC}" -ForegroundColor Blue
    docker compose --profile "${Service}" pull

    Write-Host "${BLUE}🚀 启动服务...${NC}" -ForegroundColor Blue
    docker compose --profile "${Service}" up -d

    Write-Host "${BLUE}⏳ 等待服务启动...${NC}" -ForegroundColor Blue
    Start-Sleep -Seconds 10

    Write-Host "${BLUE}🔍 检查服务状态...${NC}" -ForegroundColor Blue
    docker compose --profile "${Service}" ps
}

# ----- Main -----
function Main {
    param(
        [string[]]$Arguments
    )

    # No arguments provided
    if ($Arguments.Count -eq 0) {
        Show-Help
        return
    }

    foreach ($arg in $Arguments) {
        switch -Wildcard ($arg) {
            "-h" { Show-Help; return }
            "--help" { Show-Help; return }
            "--prepare" { Prepare-Environment }
            "--deploy=*" { 
                $service = $arg.Substring("--deploy=".Length)
                Deploy-Service -Service $service
            }
            "--deploy" { Deploy-Service -Service "all" }
            default {
                Write-Host "${RED}Unknown option: $arg${NC}" -ForegroundColor Red
                Show-Help
                exit 1
            }
        }
    }
}

# Entry point
Main $args
