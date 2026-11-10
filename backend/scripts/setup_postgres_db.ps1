# DocuMind AI — Dedicated PostgreSQL Setup Helper
# This script securely prompts for the local PostgreSQL superuser password (without echoing or printing),
# creates the dedicated 'documind' role and 'documind_db' database, and tests pgvector availability.

param(
    [string]$Superuser = "postgres",
    [string]$Host = "localhost",
    [int]$Port = 5432,
    [string]$AppUser = "documind",
    [string]$AppDatabase = "documind_db"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " DocuMind AI — PostgreSQL Database Setup & Access Recovery" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$psqlPath = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
if (-not (Test-Path $psqlPath)) {
    $psqlCmd = Get-Command psql.exe -ErrorAction SilentlyContinue
    if ($psqlCmd) {
        $psqlPath = $psqlCmd.Source
    } else {
        Write-Error "psql.exe not found. Please ensure PostgreSQL is installed."
        exit 1
    }
}

Write-Host "Using psql: $psqlPath"
Write-Host "Target Server: $Host:$Port (Superuser: $Superuser)"
Write-Host ""

# Prompt securely for superuser password
$secPass = Read-Host -Prompt "Enter PostgreSQL superuser ($Superuser) password" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPass)
$plainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

$env:PGPASSWORD = $plainPass

try {
    # 1. Verify superuser connectivity
    Write-Host "`nTesting administrative connection..." -NoNewline
    $versionOutput = & $psqlPath -h $Host -p $Port -U $Superuser -d postgres -t -A -c "SELECT version();" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Error "Authentication failed for superuser '$Superuser'. Please check password."
        exit 1
    }
    Write-Host " [OK]" -ForegroundColor Green
    Write-Host "Connected to: $($versionOutput.Substring(0, [Math]::Min(60, $versionOutput.Length)))..."

    # 2. Prompt for dedicated application role password
    $appSecPass = Read-Host -Prompt "Enter password to set for dedicated application role '$AppUser'" -AsSecureString
    $appBstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($appSecPass)
    $appPlainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($appBstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($appBstr)

    # 3. Create or update application role
    Write-Host "`nConfiguring role '$AppUser'..." -NoNewline
    $checkRole = & $psqlPath -h $Host -p $Port -U $Superuser -d postgres -t -A -c "SELECT 1 FROM pg_roles WHERE rolname = '$AppUser';"
    if ($checkRole -eq "1") {
        & $psqlPath -h $Host -p $Port -U $Superuser -d postgres -c "ALTER ROLE $AppUser WITH LOGIN PASSWORD '$appPlainPass';" | Out-Null
        Write-Host " [UPDATED PASSWORD]" -ForegroundColor Yellow
    } else {
        & $psqlPath -h $Host -p $Port -U $Superuser -d postgres -c "CREATE ROLE $AppUser WITH LOGIN PASSWORD '$appPlainPass' NOSUPERUSER NOCREATEDB NOCREATEROLE;" | Out-Null
        Write-Host " [CREATED]" -ForegroundColor Green
    }

    # 4. Create dedicated database
    Write-Host "Configuring database '$AppDatabase'..." -NoNewline
    $checkDb = & $psqlPath -h $Host -p $Port -U $Superuser -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname = '$AppDatabase';"
    if ($checkDb -ne "1") {
        & $psqlPath -h $Host -p $Port -U $Superuser -d postgres -c "CREATE DATABASE $AppDatabase OWNER $AppUser;" | Out-Null
        Write-Host " [CREATED]" -ForegroundColor Green
    } else {
        & $psqlPath -h $Host -p $Port -U $Superuser -d postgres -c "ALTER DATABASE $AppDatabase OWNER TO $AppUser;" | Out-Null
        Write-Host " [EXISTS - OWNER SET]" -ForegroundColor Yellow
    }

    # Grant privileges
    & $psqlPath -h $Host -p $Port -U $Superuser -d $AppDatabase -c "GRANT ALL PRIVILEGES ON DATABASE $AppDatabase TO $AppUser;" | Out-Null
    & $psqlPath -h $Host -p $Port -U $Superuser -d $AppDatabase -c "GRANT ALL ON SCHEMA public TO $AppUser;" | Out-Null

    # 5. Check pgvector extension availability in target database
    Write-Host "Checking pgvector extension..." -NoNewline
    $extAvail = & $psqlPath -h $Host -p $Port -U $Superuser -d $AppDatabase -t -A -c "SELECT default_version FROM pg_available_extensions WHERE name = 'vector';"
    if ($extAvail) {
        & $psqlPath -h $Host -p $Port -U $Superuser -d $AppDatabase -c "CREATE EXTENSION IF NOT EXISTS vector;" | Out-Null
        Write-Host " [INSTALLED & READY (v$extAvail)]" -ForegroundColor Green
    } else {
        Write-Host " [NOT INSTALLED IN PG 18]" -ForegroundColor Red
        Write-Warning "pgvector extension files are not installed in PostgreSQL 18 share/extension directory."
    }

    # 6. Update local backend/.env (preserving backup)
    $envPath = Join-Path $PSScriptRoot "..\.env"
    if (Test-Path $envPath) {
        $envBak = "$envPath.bak"
        Copy-Item $envPath $envBak -Force
        Write-Host "`nBacked up existing .env to: $envBak" -ForegroundColor Cyan

        $content = Get-Content $envPath
        $newUrl = "DATABASE_URL=`"postgresql+psycopg://$($AppUser):$($appPlainPass)@$($Host):$($Port)/$($AppDatabase)`""
        $updated = $false
        $newLines = $content | ForEach-Object {
            if ($_ -match "^\s*DATABASE_URL\s*=") {
                $updated = $true
                $newUrl
            } else {
                $_
            }
        }
        if (-not $updated) {
            $newLines += $newUrl
        }
        Set-Content -Path $envPath -Value $newLines
        Write-Host "Successfully updated DATABASE_URL in backend/.env!" -ForegroundColor Green
    }

    Write-Host "`nPostgreSQL setup completed safely." -ForegroundColor Green
}
finally {
    $env:PGPASSWORD = $null
    $plainPass = $null
    $appPlainPass = $null
}

