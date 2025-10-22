#!/bin/bash

# VPN Server Startup Script
# ========================

echo "🚀 Starting VPN Database Server..."
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
if [ -z "$DB_HOST" ] || [ -z "$TS_AUTHKEY" ]; then
    echo "❌ Configurações obrigatórias não definidas no .env:"
    echo "   - DB_HOST: $DB_HOST"
    echo "   - TS_AUTHKEY: ${TS_AUTHKEY:0:20}..."
    exit 1
fi

echo "✅ Configurações validadas"
echo "📡 Database Host: $DB_HOST:$DB_PORT"
echo "🔐 Tailscale AuthKey: ${TS_AUTHKEY:0:20}..."

# Criar diretórios se não existirem
mkdir -p ts-server/state

# Iniciar serviços
echo "🐳 Iniciando containers..."
docker-compose down --remove-orphans
docker-compose up -d

# Aguardar inicialização
echo "⏳ Aguardando inicialização..."
sleep 10

# Verificar status
echo "📊 Status dos serviços:"
docker-compose ps

# Mostrar IP da VPN (se disponível)
echo ""
echo "🌐 Verificando IP da VPN..."
if docker exec ts-server tailscale ip 2>/dev/null; then
    echo "✅ VPN conectada com sucesso!"
else
    echo "⏳ VPN ainda conectando... (pode levar alguns minutos)"
fi

echo ""
echo "✅ Servidor VPN iniciado!"
echo "📋 Use 'docker-compose logs -f' para acompanhar os logs"
echo "🔍 Use 'docker exec ts-server tailscale status' para verificar conexões"