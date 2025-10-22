#!/bin/bash

# VPN Client Connection Test Script
# ==================================

echo "🔍 VPN Client Connection Test"
echo "=============================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Carregar variáveis do .env
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}❌ Arquivo .env não encontrado!${NC}"
    exit 1
fi

# Variáveis
VPN_SERVER_IP=${VPN_SERVER_IP:-100.94.199.41}
VPN_SERVER_PORT=${VPN_SERVER_PORT:-5432}
LOCAL_PORT=${LOCAL_PORT:-15432}

echo "📋 Configuração:"
echo "   VPN Server: $VPN_SERVER_IP:$VPN_SERVER_PORT"
echo "   Local Port: $LOCAL_PORT"
echo ""

# Função para verificar
check_status() {
    local description=$1
    local command=$2
    
    echo -n "   $description... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        return 1
    fi
}

# Testes
echo "🐳 Docker Containers:"
check_status "db-forwarder running" "docker ps | grep -q db-forwarder-client"
check_status "ts-client running" "docker ps | grep -q ts-client"
echo ""

echo "🌐 VPN Connection:"
check_status "VPN connected" "docker exec ts-client tailscale status 2>/dev/null | grep -q 'logged in'"
check_status "VPN IP assigned" "docker exec ts-client tailscale ip 2>/dev/null | grep -q '[0-9]'"

if docker exec ts-client tailscale ping -c 1 $VPN_SERVER_IP >/dev/null 2>&1; then
    echo -e "   Server reachable... ${GREEN}✅ OK${NC}"
else
    echo -e "   Server reachable... ${YELLOW}⚠️  No response (pode ser normal)${NC}"
fi
echo ""

echo "🔌 Port Forwarding:"
check_status "Local port listening" "netstat -an 2>/dev/null | grep -q ':$LOCAL_PORT' || ss -an 2>/dev/null | grep -q ':$LOCAL_PORT'"
check_status "Can reach VPN server" "docker exec db-forwarder nc -z $VPN_SERVER_IP $VPN_SERVER_PORT 2>/dev/null"
echo ""

echo "💾 Database Connection Test:"
if command -v nc >/dev/null 2>&1; then
    if nc -z localhost $LOCAL_PORT 2>/dev/null; then
        echo -e "   localhost:$LOCAL_PORT reachable... ${GREEN}✅ OK${NC}"
    else
        echo -e "   localhost:$LOCAL_PORT reachable... ${RED}❌ FAILED${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠️  nc command not available${NC}"
fi

echo ""
echo "📊 Summary:"
docker-compose ps

echo ""
echo "🔍 VPN Status Details:"
docker exec ts-client tailscale status 2>/dev/null || echo "Failed to get VPN status"

echo ""
echo "✅ Test completed!"