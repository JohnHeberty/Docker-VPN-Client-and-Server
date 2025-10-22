# VPN Server - Database Proxy

## 🏗️ Arquitetura

Este servidor atua como um **proxy de banco de dados via VPN**, criando uma ponte segura entre um banco de dados externo e clientes conectados via Tailscale VPN.

```
[Banco Externo] ←→ [VPN Server] ←→ [VPN Tailnet] ←→ [Cliente VPN] ←→ [localhost:15432]
```

## 📋 Componentes

### 1. **db-proxy** (ginuerzh/gost)
- Recebe conexões na porta 5432 da VPN interna  
- Encaminha para o banco de dados externo configurado
- Atua como proxy transparente

### 2. **ts-server** (tailscale)
- Cria conexão VPN usando Tailscale
- Compartilha rede com o db-proxy (sidecar pattern)
- Anuncia rotas se necessário

### 3. **healthcheck** (opcional)
- Monitora saúde dos serviços
- Logs de status

## ⚙️ Configuração

### 1. Configure o arquivo `.env`:

```bash
# Dados do banco externo
DB_HOST=your-database-server.com
DB_PORT=5432
DB_USER=your_user
DB_PASSWORD=your_password
DB_NAME=your_database

# Tailscale Auth Key (mesmo do cliente)
TS_AUTHKEY=tskey-auth-...
```

### 2. Execute o servidor:

```bash
cd SERVER
docker-compose up -d
```

### 3. Verifique a conexão VPN:

```bash
# Ver logs do Tailscale
docker-compose logs ts-server

# Ver IP atribuído na VPN
docker exec ts-server tailscale ip
```

## 🔧 Funcionamento

1. **Server** conecta ao banco externo via `DB_HOST:DB_PORT`
2. **Server** disponibiliza proxy na porta `5432` da VPN interna
3. **Client** conecta ao server via VPN e acessa o banco
4. **Client** externaliza no `localhost:15432` para aplicações locais

## 📊 Monitoramento

```bash
# Status geral
docker-compose ps

# Logs do proxy
docker-compose logs db-proxy

# Logs da VPN  
docker-compose logs ts-server

# Health check
docker-compose logs healthcheck
```

## 🔐 Segurança

- ✅ Conexão criptografada via Tailscale VPN
- ✅ Banco não exposto diretamente na internet
- ✅ Proxy isolado em containers
- ✅ Acesso controlado por Auth Keys do Tailscale

## 🚀 Exemplo de Uso

Depois de configurar servidor e cliente:

```bash
# No cliente, conecte ao banco via localhost
psql -h localhost -p 15432 -U your_user -d your_database

# Ou use DBeaver/pgAdmin apontando para localhost:15432
```