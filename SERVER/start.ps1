# VPN Server Startup Script - PowerShell
# ====================================== 

Write-Host "🚀 Starting VPN Database Server..." -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Verificar se .env existe
if (-Not (Test-Path ".env")) {
    Write-Host "❌ Arquivo .env não encontrado!" -ForegroundColor Red
    Write-Host "📝 Configure as variáveis no arquivo .env" -ForegroundColor Yellow
    exit 1
}

# Ler configurações do .env
$envContent = Get-Content .env
$config = @{}
foreach ($line in $envContent) {
    if ($line -match "^([^#].*?)=(.*)$") {
        $config[$matches[1]] = $matches[2]
    }
}

# Validar configurações essenciais
if (-Not $config["DB_HOST"] -or -Not $config["TS_AUTHKEY"]) {
    Write-Host "❌ Configurações obrigatórias não definidas no .env:" -ForegroundColor Red
    Write-Host "   - DB_HOST: $($config['DB_HOST'])" -ForegroundColor Yellow
    Write-Host "   - TS_AUTHKEY: $($config['TS_AUTHKEY'].Substring(0,20))..." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Configurações validadas" -ForegroundColor Green
Write-Host "📡 Database Host: $($config['DB_HOST']):$($config['DB_PORT'])" -ForegroundColor Cyan
Write-Host "🔐 Tailscale AuthKey: $($config['TS_AUTHKEY'].Substring(0,20))..." -ForegroundColor Cyan

# Criar diretórios se não existirem
if (-Not (Test-Path "ts-server\state")) {
    New-Item -ItemType Directory -Path "ts-server\state" -Force | Out-Null
}

# Iniciar serviços
Write-Host "🐳 Iniciando containers..." -ForegroundColor Yellow
docker-compose down --remove-orphans
docker-compose up -d

# Aguardar inicialização
Write-Host "⏳ Aguardando inicialização..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verificar status
Write-Host "📊 Status dos serviços:" -ForegroundColor Cyan
docker-compose ps

# Mostrar IP da VPN (se disponível)
Write-Host ""
Write-Host "🌐 Verificando IP da VPN..." -ForegroundColor Yellow
try {
    $vpnIP = docker exec ts-server tailscale ip 2>$null
    if ($vpnIP) {
        Write-Host "✅ VPN conectada com sucesso! IP: $vpnIP" -ForegroundColor Green
    }
} catch {
    Write-Host "⏳ VPN ainda conectando... (pode levar alguns minutos)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Servidor VPN iniciado!" -ForegroundColor Green
Write-Host "📋 Use 'docker-compose logs -f' para acompanhar os logs" -ForegroundColor Cyan
Write-Host "🔍 Use 'docker exec ts-server tailscale status' para verificar conexões" -ForegroundColor Cyan