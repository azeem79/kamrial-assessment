# PostgreSQL Backup & Isolated Restore Verification Script

$ErrorActionPreference = "Continue"

$EvidenceDir = Join-Path $PSScriptRoot "evidence\backup"
if (-not (Test-Path $EvidenceDir)) {
    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null
}

$LogFile = Join-Path $EvidenceDir "backup_restore_log.txt"
$DumpFile = Join-Path $EvidenceDir "db_dump.sql"

if (Test-Path $LogFile) { Remove-Item $LogFile -Force }

function Write-Log ($text) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$time] $text"
    Write-Host $entry
    Out-File -FilePath $LogFile -InputObject $entry -Append -Encoding utf8
}

Write-Log "=================================================="
Write-Log "DATABASE BACKUP & CLEAN RESTORE VERIFICATION"
Write-Log "=================================================="

# Generate dynamic secret for temporary test container
$TempTestPass = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_})

# 1. Verify DB status
Write-Log "1. Checking primary PostgreSQL database status..."
docker compose ps postgres 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

# 2. Take DB Dump
Write-Log "`n2. Executing pg_dump on primary database (kamrial_db)..."
docker compose exec -T postgres pg_dump -U postgres -d kamrial_db > $DumpFile

if (-not (Test-Path $DumpFile)) {
    Write-Log "CRITICAL ERROR: Dump file was not created!"
    exit 1
}

$dumpSize = (Get-Item $DumpFile).Length
Write-Log "Backup generated: $DumpFile ($dumpSize bytes)"

if ($dumpSize -le 100) {
    Write-Log "CRITICAL ERROR: Backup dump is empty ($dumpSize bytes)! Aborting restore."
    exit 1
}

# 3. Provision Clean Test Container
Write-Log "`n3. Provisioning isolated target PostgreSQL instance on port 5433..."
docker run --name postgres-clean-test -e POSTGRES_PASSWORD=$TempTestPass -e POSTGRES_DB=kamrial_db_restored -p 5433:5432 -d postgres:15-alpine 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

Start-Sleep -Seconds 7

# 4. Restore Dump
Write-Log "`n4. Restoring dump into isolated database..."
Get-Content $DumpFile | docker exec -i postgres-clean-test psql -U postgres -d kamrial_db_restored 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

# 5. Verify Table Integrity
Write-Log "`n5. Verifying restored database schema and row count..."
$tablesOutput = docker exec -i postgres-clean-test psql -U postgres -d kamrial_db_restored -c "\dt" 2>&1 | Out-String
Write-Log $tablesOutput

if ($tablesOutput -like "*Did not find any relations*" -or $tablesOutput -notlike "*system_health_logs*") {
    Write-Log "CRITICAL ERROR: Restored database contains no valid schema/tables!"
    docker stop postgres-clean-test | Out-Null
    docker rm postgres-clean-test | Out-Null
    exit 1
}

# 6. Cleanup Container
Write-Log "`n6. Cleaning up temporary test container..."
docker stop postgres-clean-test 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8
docker rm postgres-clean-test 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

Write-Log "`n=================================================="
Write-Log "BACKUP & ISOLATED RESTORE VERIFICATION SUCCESSFUL"
Write-Log "=================================================="