# VPN Client Startup Script - PowerShell
# ======================================

Write-Host "🚀 Starting VPN Database Client..." -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Verificar se .env existe
if (-Not (Test-Path ".env")) {
    Write-Host "❌ Arquivo .env não encontrado!" -ForegroundColor Red
    Write-Host "📝 Copie .env.example para .env e configure as variáveis" -ForegroundColor Yellow
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
if (-Not $config["VPN_SERVER_IP"] -or -Not $config["TS_AUTHKEY"]) {
    Write-Host "❌ Configurações obrigatórias não definidas no .env:" -ForegroundColor Red
    Write-Host "   - VPN_SERVER_IP: $($config['VPN_SERVER_IP'])" -ForegroundColor Yellow
    Write-Host "   - TS_AUTHKEY: $($config['TS_AUTHKEY'].Substring(0,20))..." -ForegroundColor Yellow
    exit 1
}

$localPort = if ($config["LOCAL_PORT"]) { $config["LOCAL_PORT"] } else { "15432" }
$localInterface = if ($config["LOCAL_INTERFACE"]) { $config["LOCAL_INTERFACE"] } else { "127.0.0.1" }
$vpnServerPort = if ($config["VPN_SERVER_PORT"]) { $config["VPN_SERVER_PORT"] } else { "5432" }

Write-Host "✅ Configurações validadas" -ForegroundColor Green
Write-Host "📡 VPN Server: $($config['VPN_SERVER_IP']):$vpnServerPort" -ForegroundColor Cyan
Write-Host "🏠 Local Port: ${localInterface}:${localPort}" -ForegroundColor Cyan
Write-Host "🔐 Tailscale AuthKey: $($config['TS_AUTHKEY'].Substring(0,20))..." -ForegroundColor Cyan

# Criar diretórios se não existirem
if (-Not (Test-Path "ts-authkey\state")) {
    New-Item -ItemType Directory -Path "ts-authkey\state" -Force | Out-Null
}
if (-Not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" -Force | Out-Null
}

# Parar containers antigos
Write-Host "🛑 Parando containers antigos..." -ForegroundColor Yellow
docker-compose down --remove-orphans 2>$null | Out-Null

# Iniciar serviços
Write-Host "🐳 Iniciando containers..." -ForegroundColor Yellow
docker-compose up -d

# Aguardar inicialização
Write-Host "⏳ Aguardando inicialização..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verificar status
Write-Host ""
Write-Host "📊 Status dos serviços:" -ForegroundColor Cyan
docker-compose ps

# Verificar VPN
Write-Host ""
Write-Host "🌐 Verificando conexão VPN..." -ForegroundColor Yellow
try {
    $vpnIP = docker exec ts-client tailscale ip 2>$null
    if ($vpnIP) {
        Write-Host "✅ VPN conectada! IP: $vpnIP" -ForegroundColor Green
        
        # Testar ping no servidor
        Write-Host "🔍 Testando conectividade com servidor VPN..." -ForegroundColor Yellow
        docker exec ts-client tailscale ping -c 1 $config['VPN_SERVER_IP'] 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Servidor VPN acessível via ping" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Servidor VPN não responde ao ping (pode estar normal)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "⏳ VPN ainda conectando... (pode levar alguns minutos)" -ForegroundColor Yellow
}

# Verificar porta local
Write-Host ""
Write-Host "🔍 Verificando porta local..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
$portCheck = netstat -an | Select-String ":$localPort"
if ($portCheck) {
    Write-Host "✅ Porta local $localPort está escutando" -ForegroundColor Green
} else {
    Write-Host "⏳ Porta $localPort pode levar alguns segundos..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Cliente VPN iniciado!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
Write-Host "   1. Use 'docker-compose logs -f' para acompanhar os logs" -ForegroundColor White
Write-Host "   2. Conecte suas aplicações em localhost:$localPort" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Exemplos de conexão:" -ForegroundColor Cyan
Write-Host "   psql -h localhost -p $localPort -U usuario -d database" -ForegroundColor White
Write-Host "   mysql -h localhost -P $localPort -u usuario -p" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Comandos úteis:" -ForegroundColor Cyan
Write-Host "   docker exec ts-client tailscale status" -ForegroundColor White
Write-Host "   docker exec ts-client tailscale ping $($config['VPN_SERVER_IP'])" -ForegroundColor White
Write-Host "   docker-compose logs db-forwarder" -ForegroundColor White