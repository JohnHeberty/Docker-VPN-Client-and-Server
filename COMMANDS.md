# 🔧 Comandos Úteis - VPN Client-Server

## 🚀 Inicialização

### Servidor
```bash
cd SERVER
docker-compose up -d                           # Iniciar
docker-compose -f compose.advanced.yaml up -d  # Com monitoramento
.\start.ps1                                    # Windows
./start.sh                                     # Linux/Mac
```

### Cliente
```bash
cd CLIENT
docker-compose up -d                           # Iniciar
docker-compose -f compose.advanced.yaml up -d  # Com monitoramento
.\start.ps1                                    # Windows
./start.sh                                     # Linux/Mac
```

## 📊 Monitoramento

### Status Geral
```bash
docker-compose ps                              # Status dos containers
docker-compose logs                            # Todos os logs
docker-compose logs -f                         # Logs em tempo real
docker-compose logs --tail=100 ts-server       # Últimas 100 linhas
```

### VPN Status
```bash
# Servidor
docker exec ts-server tailscale status         # Status completo
docker exec ts-server tailscale ip             # IP na VPN
docker exec ts-server tailscale netcheck       # Diagnóstico de rede

# Cliente
docker exec ts-client tailscale status         # Status completo
docker exec ts-client tailscale ip             # IP na VPN
docker exec ts-client tailscale ping <SERVER_IP>  # Ping no servidor
```

### Logs Específicos
```bash
# Servidor
docker-compose logs db-proxy                   # Logs do proxy
docker-compose logs ts-server                  # Logs da VPN
docker-compose logs healthcheck                # Logs do monitor

# Cliente
docker-compose logs db-forwarder               # Logs do forwarder
docker-compose logs ts-client                  # Logs da VPN
docker-compose logs connection-monitor         # Logs do monitor
```

## 🔍 Diagnóstico

### Testar Conectividade

#### Servidor
```bash
# Testar acesso ao banco externo
docker exec db-proxy nc -z $DB_HOST $DB_PORT

# Verificar porta interna
docker exec ts-server netstat -tuln | grep 5432

# Listar peers conectados
docker exec ts-server tailscale status
```

#### Cliente
```bash
# Testar acesso ao servidor VPN
docker exec ts-client tailscale ping $VPN_SERVER_IP

# Verificar porta local (Windows)
netstat -an | findstr 15432

# Verificar porta local (Linux/Mac)
netstat -an | grep 15432
lsof -i :15432

# Testar proxy interno
docker exec db-forwarder nc -z $VPN_SERVER_IP $VPN_SERVER_PORT

# Script de teste completo
.\test-connection.ps1  # Windows
./test-connection.sh   # Linux/Mac
```

### Verificar Configuração
```bash
# Ver variáveis de ambiente
docker-compose config

# Ver .env atual
cat .env             # Linux/Mac
type .env            # Windows CMD
Get-Content .env     # Windows PowerShell

# Validar compose.yaml
docker-compose config --quiet
```

## 🔄 Gerenciamento

### Restart
```bash
docker-compose restart                         # Restart todos
docker-compose restart ts-server               # Restart específico
docker-compose restart ts-client
```

### Stop/Start
```bash
docker-compose stop                            # Parar todos
docker-compose start                           # Iniciar todos
docker-compose down                            # Parar e remover
docker-compose up -d                           # Criar e iniciar
```

### Rebuild
```bash
docker-compose down                            # Parar
docker-compose pull                            # Atualizar imagens
docker-compose up -d --force-recreate          # Recriar containers
```

### Limpar Estado (CUIDADO!)
```bash
# Servidor
docker-compose down
rm -rf ts-server/state/*
docker-compose up -d

# Cliente
docker-compose down
rm -rf ts-authkey/state/*
docker-compose up -d
```

## 🐛 Debug

### Modo Verbose
```bash
# Adicionar -v ao comando do GOST no compose.yaml
command: >
  -L=tcp://:5432/${DB_HOST}:${DB_PORT} -v

# Restart para aplicar
docker-compose restart
```

### Acessar Container
```bash
# Entrar no container
docker exec -it ts-server sh              # Servidor VPN
docker exec -it ts-client sh              # Cliente VPN
docker exec -it db-proxy sh               # Proxy do servidor
docker exec -it db-forwarder sh           # Forwarder do cliente

# Executar comando único
docker exec ts-server tailscale status
docker exec db-proxy nc -z 8.8.8.8 53
```

### Inspecionar Container
```bash
docker inspect ts-server                  # Detalhes completos
docker inspect ts-client
docker stats                              # Uso de recursos
docker top ts-server                      # Processos rodando
```

## 🔧 Manutenção

### Atualizar Imagens
```bash
docker-compose pull                       # Baixar novas versões
docker-compose up -d                      # Aplicar updates
```

### Limpar Recursos Não Usados
```bash
docker system prune                       # Limpar tudo não usado
docker image prune                        # Limpar imagens não usadas
docker volume prune                       # Limpar volumes não usados
docker network prune                      # Limpar redes não usadas
```

### Backup de Estado
```bash
# Servidor
tar -czf vpn-server-backup.tar.gz SERVER/ts-server/state/

# Cliente
tar -czf vpn-client-backup.tar.gz CLIENT/ts-authkey/state/
```

### Restaurar Backup
```bash
# Servidor
docker-compose down
rm -rf ts-server/state/*
tar -xzf vpn-server-backup.tar.gz -C .
docker-compose up -d

# Cliente
docker-compose down
rm -rf ts-authkey/state/*
tar -xzf vpn-client-backup.tar.gz -C .
docker-compose up -d
```

## 📈 Performance

### Ver Estatísticas
```bash
docker stats                              # Real-time stats
docker stats --no-stream                  # Snapshot único
```

### Ver Uso de Disco
```bash
docker system df                          # Resumo
docker system df -v                       # Detalhado
```

### Limitar Recursos (compose.yaml)
```yaml
services:
  ts-server:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

## 🔐 Segurança

### Rotacionar Auth Key
```bash
# 1. Gerar nova key no Tailscale Admin
# 2. Atualizar .env
# 3. Recriar containers
docker-compose down
docker-compose up -d
```

### Ver Permissões
```bash
ls -la ts-server/state/                   # Linux/Mac
dir ts-server\state\                      # Windows
```

### Verificar Exposição de Portas
```bash
docker-compose ps                         # Ver portas mapeadas
netstat -tuln | grep LISTEN               # Portas escutando
```

## 🧪 Testes

### Testar Conexão de Banco (PostgreSQL)
```bash
# Do cliente
psql -h localhost -p 15432 -U postgres -c "SELECT version();"

# Usando Docker
docker run --rm -it postgres:alpine psql -h host.docker.internal -p 15432 -U postgres
```

### Benchmark de Latência
```bash
# Ping VPN
docker exec ts-client tailscale ping -c 10 $VPN_SERVER_IP

# Ping banco (através do proxy)
docker exec db-forwarder sh -c 'time nc -z $VPN_SERVER_IP $VPN_SERVER_PORT'
```

### Teste de Throughput
```bash
# iperf3 entre cliente e servidor (se disponível)
# No servidor
docker run --rm -p 5201:5201 networkstatic/iperf3 -s

# No cliente
docker run --rm networkstatic/iperf3 -c <VPN_SERVER_IP>
```

## 📝 Logs Avançados

### Exportar Logs
```bash
# Todos os logs
docker-compose logs > full-logs.txt

# Logs específicos com timestamp
docker-compose logs --timestamps ts-server > server-logs.txt

# Logs desde determinado tempo
docker-compose logs --since="2024-01-01T00:00:00"
```

### Seguir Múltiplos Logs
```bash
# Windows PowerShell
Get-Content -Path (docker-compose logs -f | Out-File -FilePath logs.txt -Append)

# Linux/Mac
docker-compose logs -f | tee logs.txt
```

## 🎯 Troubleshooting Específico

### "Connection refused"
```bash
# Verificar se container está rodando
docker-compose ps

# Verificar logs
docker-compose logs db-forwarder

# Testar porta interna
docker exec db-forwarder nc -z localhost 15432
```

### "No route to host"
```bash
# Verificar status VPN
docker exec ts-client tailscale status

# Verificar rotas
docker exec ts-client ip route

# Testar ping
docker exec ts-client ping $VPN_SERVER_IP
```

### "Timeout"
```bash
# Verificar se servidor está acessível
docker exec ts-client tailscale ping $VPN_SERVER_IP

# Verificar se banco externo está acessível (no servidor)
docker exec db-proxy nc -z $DB_HOST $DB_PORT

# Ver latência
docker exec ts-client tailscale ping -c 5 $VPN_SERVER_IP
```