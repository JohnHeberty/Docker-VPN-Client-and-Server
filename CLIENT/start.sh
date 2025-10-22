#!/bin/bash

# VPN Client Startup Script
# ========================

echo "🚀 Starting VPN Database Client..."
echo "=================================="

# Verificar se .env existe
if [ ! -f .env ]; then
    echo "❌ Arquivo .env não encontrado!"
    echo "📝 Copie .env.example para .env e configure as variáveis"
    exit 1
fi

# Carregar variáveis do .env
source .env

# Validar configurações essenciais
if [ -z "$VPN_SERVER_IP" ] || [ -z "$TS_AUTHKEY" ]; then
    echo "❌ Configurações obrigatórias não definidas no .env:"
    echo "   - VPN_SERVER_IP: $VPN_SERVER_IP"
    echo "   - TS_AUTHKEY: ${TS_AUTHKEY:0:20}..."
    exit 1
fi

echo "✅ Configurações validadas"
echo "📡 VPN Server: $VPN_SERVER_IP:${VPN_SERVER_PORT:-5432}"
echo "🏠 Local Port: ${LOCAL_INTERFACE:-127.0.0.1}:${LOCAL_PORT:-15432}"
echo "🔐 Tailscale AuthKey: ${TS_AUTHKEY:0:20}..."

# Criar diretórios se não existirem
mkdir -p ts-authkey/state
mkdir -p logs

# Parar containers antigos
echo "🛑 Parando containers antigos..."
docker-compose down --remove-orphans 2>/dev/null

# Iniciar serviços
echo "🐳 Iniciando containers..."
docker-compose up -d

# Aguardar inicialização
echo "⏳ Aguardando inicialização..."
sleep 10

# Verificar status
echo ""
echo "📊 Status dos serviços:"
docker-compose ps

# Verificar VPN
echo ""
echo "🌐 Verificando conexão VPN..."
if docker exec ts-client tailscale ip 2>/dev/null; then
    VPN_IP=$(docker exec ts-client tailscale ip 2>/dev/null)
    echo "✅ VPN conectada! IP: $VPN_IP"
    
    # Testar ping no servidor
    echo "🔍 Testando conectividade com servidor VPN..."
    if docker exec ts-client tailscale ping -c 1 $VPN_SERVER_IP >/dev/null 2>&1; then
        echo "✅ Servidor VPN acessível via ping"
    else
        echo "⚠️  Servidor VPN não responde ao ping (pode estar normal)"
    fi
else
    echo "⏳ VPN ainda conectando... (pode levar alguns minutos)"
fi

# Verificar porta local
echo ""
echo "🔍 Verificando porta local..."
sleep 2
if netstat -an 2>/dev/null | grep -q ":${LOCAL_PORT:-15432}"; then
    echo "✅ Porta local ${LOCAL_PORT:-15432} está escutando"
elif ss -an 2>/dev/null | grep -q ":${LOCAL_PORT:-15432}"; then
    echo "✅ Porta local ${LOCAL_PORT:-15432} está escutando"
else
    echo "⏳ Porta ${LOCAL_PORT:-15432} pode levar alguns segundos..."
fi

echo ""
echo "✅ Cliente VPN iniciado!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Use 'docker-compose logs -f' para acompanhar os logs"
echo "   2. Conecte suas aplicações em localhost:${LOCAL_PORT:-15432}"
echo ""
echo "🔧 Exemplos de conexão:"
echo "   psql -h localhost -p ${LOCAL_PORT:-15432} -U usuario -d database"
echo "   mysql -h localhost -P ${LOCAL_PORT:-15432} -u usuario -p"
echo ""
echo "🔍 Comandos úteis:"
echo "   docker exec ts-client tailscale status    # Status da VPN"
echo "   docker exec ts-client tailscale ping $VPN_SERVER_IP  # Ping no servidor"
echo "   docker-compose logs db-forwarder          # Logs do forwarder"