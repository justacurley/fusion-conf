#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Runs the Docker Compose configuration for PSU (PowerShell Universal)

.DESCRIPTION
    This script starts the PowerShell Universal container using docker-compose.
    It includes error handling and status checking.

.PARAMETER Down
    Stops and removes the containers instead of starting them

.PARAMETER Rebuild
    Forces a rebuild of the containers before starting

.PARAMETER Logs
    Shows the logs for the running containers

.EXAMPLE
    .\run-docker.ps1
    Starts the PSU container

.EXAMPLE
    .\run-docker.ps1 -Down
    Stops and removes the PSU container

.EXAMPLE
    .\run-docker.ps1 -Rebuild
    Rebuilds and starts the PSU container

.EXAMPLE
    .\run-docker.ps1 -Logs
    Shows logs for the running containers
#>

param(
    [switch]$Down,
    [switch]$Rebuild,
    [switch]$Logs
)

# Set the script location as working directory
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptPath

# Check if Docker is running
try {
    docker version | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
}
catch {
    Write-Error "Docker is not running or not installed. Please start Docker Desktop."
    exit 1
}

# Check if docker-compose.yml exists
if (-not (Test-Path "docker-compose.yml")) {
    Write-Error "docker-compose.yml not found in current directory: $ScriptPath"
    exit 1
}

try {
    if ($Down) {
        Write-Host "Stopping and removing PSU containers..." -ForegroundColor Yellow
        docker-compose down
        Write-Host "✓ PSU containers stopped and removed" -ForegroundColor Green
    }
    elseif ($Logs) {
        Write-Host "Showing logs for PSU containers..." -ForegroundColor Yellow
        docker-compose logs -f
    }
    elseif ($Rebuild) {
        Write-Host "Rebuilding and starting PSU containers..." -ForegroundColor Yellow
        docker-compose down
        docker-compose up --build -d
        Write-Host "✓ PSU containers rebuilt and started" -ForegroundColor Green
        Write-Host "PowerShell Universal should be available at: http://localhost:5000" -ForegroundColor Cyan
    }
    else {
        Write-Host "Starting PSU containers..." -ForegroundColor Yellow
        docker-compose up -d
        Write-Host "✓ PSU containers started" -ForegroundColor Green
        Write-Host "PowerShell Universal should be available at: http://localhost:5000" -ForegroundColor Cyan
        
        # Wait a moment and check if container is running
        Start-Sleep -Seconds 3
        $containerStatus = docker-compose ps --services --filter "status=running"
        if ($containerStatus -contains "PSU") {
            Write-Host "✓ PSU container is running successfully" -ForegroundColor Green
        }
        else {
            Write-Warning "PSU container may not be running properly. Check logs with: .\run-docker.ps1 -Logs"
        }
    }
}
catch {
    Write-Error "Error running docker-compose: $($_.Exception.Message)"
    exit 1
}

# Show running containers
if (-not $Down -and -not $Logs) {
    Write-Host "`nRunning containers:" -ForegroundColor Yellow
    docker-compose ps
}
