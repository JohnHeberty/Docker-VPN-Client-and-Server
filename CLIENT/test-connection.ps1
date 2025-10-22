# VPN Client Connection Test Script - PowerShell
# ==============================================

Write-Host "🔍 VPN Client Connection Test" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Carregar variáveis do .env
if (-Not (Test-Path ".env")) {
    Write-Host "❌ Arquivo .env não encontrado!" -ForegroundColor Red
    exit 1
}

$envContent = Get-Content .env
$config = @{}
foreach ($line in $envContent) {
    if ($line -match "^([^#].*?)=(.*)$") {
        $config[$matches[1]] = $matches[2]
    }
}

$vpnServerIP = if ($config["VPN_SERVER_IP"]) { $config["VPN_SERVER_IP"] } else { "100.94.199.41" }
$vpnServerPort = if ($config["VPN_SERVER_PORT"]) { $config["VPN_SERVER_PORT"] } else { "5432" }
$localPort = if ($config["LOCAL_PORT"]) { $config["LOCAL_PORT"] } else { "15432" }

Write-Host "📋 Configuração:" -ForegroundColor Cyan
Write-Host "   VPN Server: ${vpnServerIP}:${vpnServerPort}"
Write-Host "   Local Port: ${localPort}"
Write-Host ""

# Função para verificar status
function Check-Status {
    param(
        [string]$Description,
        [scriptblock]$Command
    )
    
    Write-Host "   $Description... " -NoNewline
    
    try {
        $result = & $Command 2>$null
        if ($LASTEXITCODE -eq 0 -or $result) {
            Write-Host "✅ OK" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ FAILED" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ FAILED" -ForegroundColor Red
        return $false
    }
}

# Testes
Write-Host "🐳 Docker Containers:" -ForegroundColor Cyan
Check-Status "db-forwarder running" { docker ps | Select-String "db-forwarder-client" }
Check-Status "ts-client running" { docker ps | Select-String "ts-client" }
Write-Host ""

Write-Host "🌐 VPN Connection:" -ForegroundColor Cyan
Check-Status "VPN connected" { docker exec ts-client tailscale status 2>$null | Select-String "logged in" }
Check-Status "VPN IP assigned" { docker exec ts-client tailscale ip 2>$null | Select-String "[0-9]" }

Write-Host "   Server reachable... " -NoNewline
docker exec ts-client tailscale ping -c 1 $vpnServerIP 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ OK" -ForegroundColor Green
} else {
    Write-Host "⚠️  No response (pode ser normal)" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "🔌 Port Forwarding:" -ForegroundColor Cyan
Check-Status "Local port listening" { netstat -an | Select-String ":${localPort}" }
Check-Status "Can reach VPN server" { docker exec db-forwarder nc -z $vpnServerIP $vpnServerPort 2>$null }
Write-Host ""

Write-Host "💾 Database Connection Test:" -ForegroundColor Cyan
Write-Host "   localhost:${localPort} reachable... " -NoNewline
$portTest = Test-NetConnection -ComputerName localhost -Port $localPort -WarningAction SilentlyContinue
if ($portTest.TcpTestSucceeded) {
    Write-Host "✅ OK" -ForegroundColor Green
} else {
    Write-Host "❌ FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
docker-compose ps

Write-Host ""
Write-Host "🔍 VPN Status Details:" -ForegroundColor Cyan
docker exec ts-client tailscale status 2>$null

Write-Host ""
Write-Host "✅ Test completed!" -ForegroundColor Green