<#
.SYNOPSIS
    Installs and configures pre-commit and related tools on Windows
.DESCRIPTION
    This script installs pre-commit hooks and required dependencies on Windows.
    It uses Chocolatey to install packages and configures pre-commit.
.NOTES
    Requires administrative privileges.
    Author: Kirk
    Version: 1.1
#>

# Function to check execution policy
function Test-ExecutionPolicy {
    if ($(Get-ExecutionPolicy) -eq "Restricted") {
        Write-Host "Error: ExecutionPolicy is set to Restricted. Please run in an Admin PowerShell shell" -ForegroundColor Red
        exit 1
    }
}

# Function to check if running as admin
function Test-IsAdmin {
    <#
    .SYNOPSIS
        Checks if the current PowerShell instance is running with elevated privileges.
    .OUTPUTS
        System.Boolean
            True if the current PowerShell is elevated, false if not.
    #>
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Host "Error: Failed to determine if the current user has elevated privileges. The error was: '$_'" -ForegroundColor Red
        exit 1
    }
}

# Function to install packages with error handling
function Install-Package {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    Write-Host "Installing $PackageName..." -ForegroundColor Yellow
    try {
        choco install $PackageName -y
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to install $PackageName" -ForegroundColor Red
            exit 1
        }
        Write-Host "$PackageName installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: An exception occurred while installing $PackageName - $_" -ForegroundColor Red
        exit 1
    }
}

# Function to install Python packages with error handling
function Install-PythonPackage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )

    Write-Host "Installing Python package $PackageName..." -ForegroundColor Yellow
    try {
        python -m pip install $PackageName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to install Python package $PackageName" -ForegroundColor Red
            exit 1
        }
        Write-Host "Python package $PackageName installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: An exception occurred while installing Python package $PackageName - $_" -ForegroundColor Red
        exit 1
    }
}

# Script start
Write-Host "Starting pre-commit installation and setup..." -ForegroundColor Cyan

# Check requirements
Test-ExecutionPolicy
if ($(Test-IsAdmin) -ne $true) {
    Write-Host "Error: User doesn't have elevated privileges. Please run in an Admin PowerShell shell" -ForegroundColor Red
    exit 1
}

# Install Chocolatey if not already installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to install Chocolatey" -ForegroundColor Red
            exit 1
        }
        Write-Host "Chocolatey installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: An exception occurred while installing Chocolatey - $_" -ForegroundColor Red
        exit 1
    }

    # Refresh environment to use choco
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Install required packages
$packages = @(
    "git",
    "python",
    "make",
    "terraform",
    "terraform-docs"
)

foreach ($package in $packages) {
    Install-Package -PackageName $package
}

# Refresh environment again after installing packages
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Install Python packages
$pythonPackages = @(
    "pre-commit",
    "flake8",
    "checkov",
    "bandit",
    "black",
    "pip-tools"
)

foreach ($package in $pythonPackages) {
    Install-PythonPackage -PackageName $package
}

# Install from requirements.txt if it exists
if (Test-Path "requirements.txt") {
    Write-Host "Installing Python packages from requirements.txt..." -ForegroundColor Yellow
    try {
        python -m pip install -r requirements.txt
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Warning: Some issues occurred installing packages from requirements.txt" -ForegroundColor Yellow
        }
        else {
            Write-Host "Python packages from requirements.txt installed successfully" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Warning: An exception occurred while installing packages from requirements.txt - $_" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Warning: requirements.txt not found" -ForegroundColor Yellow
}

# Configure pre-commit
if (Test-Path ".git") {
    Write-Host "Configuring pre-commit hooks..." -ForegroundColor Yellow
    try {
        pre-commit install
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Warning: Failed to install pre-commit hooks" -ForegroundColor Yellow
        }
        else {
            Write-Host "Pre-commit hooks installed successfully" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Warning: An exception occurred while setting up pre-commit hooks - $_" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Warning: .git directory not found. Cannot install pre-commit hooks." -ForegroundColor Yellow
}

Write-Host "Setup completed successfully!" -ForegroundColor Green
Write-Host "You can now use pre-commit in your Git workflow." -ForegroundColor Cyan
