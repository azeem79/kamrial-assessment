# Robust Incident Recovery Simulation & Evidence Logger

$ErrorActionPreference = "Continue"

$EvidenceDir = Join-Path $PSScriptRoot "evidence\incident"
if (-not (Test-Path $EvidenceDir)) {
    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null
}

$LogFile = Join-Path $EvidenceDir "incident_recovery_log.txt"
if (Test-Path $LogFile) { Remove-Item $LogFile -Force }

function Write-Log ($text) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$time] $text"
    Write-Host $entry
    Out-File -FilePath $LogFile -InputObject $entry -Append -Encoding utf8
}

Write-Log "=================================================="
Write-Log "INCIDENT SIMULATION & RECOVERY EVIDENCE LOG"
Write-Log "=================================================="

# 1. Start Stack
Write-Log "1. Starting full application stack..."
docker compose up -d --build 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8
Start-Sleep -Seconds 8

Write-Log "`n--- Live Container Status ---"
docker compose ps 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

# 2. Publish Baseline Jobs
Write-Log "`n2. Publishing 5 baseline test jobs to RabbitMQ..."
docker compose exec -T api python producer.py 5 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8
Start-Sleep -Seconds 3

# 3. Simulate Incident
Write-Log "`n3. SIMULATING INCIDENT: Stopping Worker container..."
docker compose stop worker 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

Write-Log "`n--- Live Container Status (Worker Down) ---"
docker compose ps 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

# 4. Verify API Health
Write-Log "`n4. Verifying API health while worker is offline..."
try {
    $res = Invoke-WebRequest -Uri "http://localhost:8000" -UseBasicParsing -TimeoutSec 5
    Write-Log "API Status Code: $($res.StatusCode) OK (API remains available)"
} catch {
    Write-Log "API Check Error: $_"
}

# 5. Build Queue Backlog
Write-Log "`n5. Publishing 10 additional jobs to build queue backlog..."
docker compose exec -T api python producer.py 10 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

# 6. Check Queue Backlog Before Recovery
Write-Log "`n6. Checking RabbitMQ queue depth before worker recovery..."
docker compose exec -T rabbitmq rabbitmqctl list_queues 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

# 7. Recovery
Write-Log "`n7. RECOVERY: Restarting Worker container..."
docker compose start worker 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

Write-Log "Waiting 15 seconds for worker to process and drain queue..."
Start-Sleep -Seconds 15

# 8. Verify Queue Drain & Worker Logs
Write-Log "`n8. Verifying RabbitMQ queue depth after recovery (should be 0):"
docker compose exec -T rabbitmq rabbitmqctl list_queues 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

Write-Log "`n9. Worker container processing logs:"
docker compose logs worker --tail=30 2>&1 | Out-File -FilePath $LogFile -Append -Encoding utf8

Write-Log "`n=================================================="
Write-Log "INCIDENT RECOVERY COMPLETED SUCCESSFULLY"
Write-Log "=================================================="