# 🏗️ Arquitetura VPN Cliente-Servidor com Database Proxy

## 📋 Visão Geral

Esta solução implementa uma arquitetura de VPN segura que permite acesso a bancos de dados externos através de um túnel criptografado usando Tailscale.

```
┌─────────────────┐    VPN Tunnel    ┌─────────────────┐    External    ┌─────────────────┐
│     CLIENT      │ ←────────────────→ │     SERVER      │ ──────────────→ │   DATABASE      │
│                 │                   │                 │                 │                 │
│ ┌─────────────┐ │                   │ ┌─────────────┐ │                 │ ┌─────────────┐ │
│ │   gost      │ │                   │ │   gost      │ │                 │ │ PostgreSQL  │ │
│ │ (forwarder) │ │                   │ │ (db-proxy)  │ │                 │ │   MySQL     │ │
│ │             │ │                   │ │             │ │                 │ │ SQL Server  │ │
│ └─────────────┘ │                   │ └─────────────┘ │                 │ └─────────────┘ │
│ ┌─────────────┐ │                   │ ┌─────────────┐ │                 └─────────────────┘
│ │ tailscale   │ │                   │ │ tailscale   │ │
│ │ (ts-authkey)│ │                   │ │ (ts-server) │ │
│ └─────────────┘ │                   │ └─────────────┘ │
└─────────────────┘                   └─────────────────┘
       ↓                                      
┌─────────────────┐                           
│  localhost:15432│                           
│                 │                           
│ ┌─────────────┐ │                           
│ │  DBeaver    │ │                           
│ │  pgAdmin    │ │                           
│ │  App Local  │ │                           
│ └─────────────┘ │                           
└─────────────────┘                           
```

## 🔄 Fluxo de Dados

1. **Aplicação Local** → `localhost:15432`
2. **Cliente VPN** → Forwarding via VPN Tunnel 
3. **Servidor VPN** → Recebe conexão na VPN interna `:5432`
4. **Database Proxy** → `external-db-host:5432`
5. **Banco Externo** → Processa query e responde

## 📁 Estrutura dos Projetos

### CLIENT/
```
CLIENT/
├── compose.yaml          # Docker Compose básico
├── compose.advanced.yaml # Docker Compose com monitoramento
├── .env                  # Configurações do cliente
├── .env.example          # Template de configuração
├── .gitignore           # Arquivos a ignorar no Git
├── README.md            # Documentação detalhada
├── QUICK_START.md       # Guia rápido de conexão
├── start.sh             # Script de inicialização (Linux/Mac)
├── start.ps1            # Script de inicialização (Windows)
├── test-connection.sh   # Script de teste (Linux/Mac)
├── test-connection.ps1  # Script de teste (Windows)
└── ts-authkey/
    └── state/           # Estado persistente do Tailscale
```

### SERVER/
```
SERVER/
├── compose.yaml          # Docker Compose básico
├── compose.advanced.yaml # Docker Compose com monitoramento
├── .env                  # Configurações do servidor  
├── .env.example          # Template de configuração
├── .gitignore           # Arquivos a ignorar no Git
├── README.md            # Documentação detalhada
├── start.sh             # Script de inicialização (Linux/Mac)
├── start.ps1            # Script de inicialização (Windows)
└── ts-server/
    └── state/           # Estado persistente do Tailscale
```

## ⚙️ Configuração Rápida

### 1. Configure o Servidor

```bash
cd SERVER
cp .env.example .env
# Edite .env com suas configurações
docker-compose up -d
```

### 2. Configure o Cliente  

```bash
cd CLIENT
# .env já está configurado
docker-compose up -d
```

### 3. Teste a Conexão

```bash
# Via psql
psql -h localhost -p 15432 -U seu_usuario -d sua_database

# Via DBeaver: localhost:15432
```

## 🔐 Segurança

- ✅ **Criptografia End-to-End**: Tailscale WireGuard
- ✅ **Zero Trust**: Acesso controlado por chaves
- ✅ **Isolamento**: Containers isolados
- ✅ **Sem Exposição Direta**: Banco não exposto na internet

## 📊 Monitoramento

```bash
# Status geral
docker-compose ps

# Logs em tempo real
docker-compose logs -f

# Status da VPN
docker exec ts-server tailscale status

# Health checks (compose.advanced.yaml)
docker-compose logs connection-monitor
```

## 🚀 Recursos Avançados

### compose.advanced.yaml inclui:
- ✅ Health checks automáticos
- ✅ Monitor de conectividade
- ✅ Backup automático de configuração
- ✅ Logs estruturados
- ✅ Retry automático de conexões

### Para usar a versão avançada:
```bash
docker-compose -f compose.advanced.yaml up -d

# Com backup automático
docker-compose -f compose.advanced.yaml --profile backup up -d
```

## 🔧 Troubleshooting

### Problemas Comuns:

1. **VPN não conecta**
   ```bash
   docker-compose logs ts-server
   ```

2. **Banco inacessível**
   ```bash
   docker exec db-proxy nc -z $DB_HOST $DB_PORT
   ```

3. **Cliente não conecta ao servidor**
   ```bash
   docker exec ts-authkey tailscale ping vpn-db-server
   ```

## 🎯 Casos de Uso

- ✅ **Desenvolvimento**: Acesso seguro a DBs de produção
- ✅ **Analytics**: Conectar ferramentas BI via VPN
- ✅ **Backup/Sync**: Replicação segura entre ambientes
- ✅ **Compliance**: Acesso auditável e criptografado