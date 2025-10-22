# 📂 Estrutura Completa do Projeto

```
VPN_CLIENT_SERVER/
│
├── 📄 README.md                    # Documentação principal
├── 📄 ARCHITECTURE.md              # Arquitetura e diagramas
├── 📄 COMMANDS.md                  # Comandos úteis e troubleshooting
│
├── 📁 SERVER/                      # ========== SERVIDOR VPN ==========
│   │
│   ├── 🐳 compose.yaml             # Docker Compose básico
│   ├── 🐳 compose.advanced.yaml   # Docker Compose avançado (com monitoring)
│   │
│   ├── ⚙️  .env                    # Configurações do servidor (GIT IGNORE)
│   ├── ⚙️  .env.example            # Template de configuração
│   ├── 📄 .gitignore               # Arquivos ignorados no Git
│   │
│   ├── 📖 README.md                # Documentação do servidor
│   │
│   ├── 🚀 start.sh                 # Script de inicialização (Linux/Mac)
│   ├── 🚀 start.ps1                # Script de inicialização (Windows)
│   │
│   └── 📁 ts-server/               # Estado persistente do Tailscale
│       └── 📁 state/               # ⚠️  Contém chaves privadas (GIT IGNORE)
│           ├── derpmap.cached.json
│           ├── tailscaled.state
│           └── tailscaled.log*.txt
│
└── 📁 CLIENT/                      # ========== CLIENTE VPN ==========
    │
    ├── 🐳 compose.yaml             # Docker Compose básico
    ├── 🐳 compose.advanced.yaml   # Docker Compose avançado (com monitoring)
    │
    ├── ⚙️  .env                    # Configurações do cliente (GIT IGNORE)
    ├── ⚙️  .env.example            # Template de configuração
    ├── 📄 .gitignore               # Arquivos ignorados no Git
    │
    ├── 📖 README.md                # Documentação completa do cliente
    ├── 📖 QUICK_START.md           # Guia rápido de início
    │
    ├── 🚀 start.sh                 # Script de inicialização (Linux/Mac)
    ├── 🚀 start.ps1                # Script de inicialização (Windows)
    │
    ├── 🧪 test-connection.sh       # Script de teste (Linux/Mac)
    ├── 🧪 test-connection.ps1      # Script de teste (Windows)
    │
    └── 📁 ts-authkey/              # Estado persistente do Tailscale
        └── 📁 state/               # ⚠️  Contém chaves privadas (GIT IGNORE)
            ├── derpmap.cached.json
            ├── tailscaled.state
            └── tailscaled.log*.txt
```

## 📊 Componentes por Função

### 🔧 Configuração
- `.env` - Variáveis de ambiente (credenciais, IPs, portas)
- `.env.example` - Template para criar `.env`
- `compose.yaml` - Definição dos serviços Docker
- `compose.advanced.yaml` - Versão com monitoring e backups

### 📖 Documentação
- `README.md` - Documentação específica de cada componente
- `QUICK_START.md` - Guia rápido (apenas no CLIENT)
- `ARCHITECTURE.md` - Visão geral da arquitetura (raiz)
- `COMMANDS.md` - Comandos úteis e troubleshooting (raiz)

### 🚀 Scripts
- `start.sh` / `start.ps1` - Inicialização automática
- `test-connection.sh` / `test-connection.ps1` - Testes (apenas CLIENT)

### 💾 Persistência
- `ts-server/state/` - Estado da VPN do servidor
- `ts-authkey/state/` - Estado da VPN do cliente
- ⚠️ **IMPORTANTE**: Nunca commitar estes diretórios no Git!

## 🎯 Fluxo de Uso

```
1. SETUP INICIAL
   └── Copiar .env.example → .env
   └── Configurar variáveis
   └── Executar start.ps1 ou start.sh

2. SERVIDOR
   └── Define: DB_HOST, DB_PORT, TS_AUTHKEY
   └── Conecta ao banco externo
   └── Disponibiliza via VPN interna

3. CLIENTE
   └── Define: VPN_SERVER_IP, TS_AUTHKEY
   └── Conecta ao servidor via VPN
   └── Externaliza em localhost:15432

4. APLICAÇÕES
   └── Conectam em localhost:15432
   └── DBeaver, pgAdmin, psql, etc.
```

## 🔐 Arquivos Sensíveis (Git Ignored)

```
❌ .env                           # Credenciais e configurações
❌ ts-server/state/*              # Estado VPN do servidor
❌ ts-authkey/state/*             # Estado VPN do cliente
❌ *.log                          # Logs
❌ backups/*                      # Backups automáticos
```

## 📦 Containers Docker

### SERVIDOR
1. **db-proxy** (gost)
   - Função: Proxy do banco externo
   - Porta: 5432 (interna VPN)
   
2. **ts-server** (tailscale)
   - Função: Servidor VPN
   - Network: Compartilhada com db-proxy
   
3. **healthcheck** (alpine) [opcional]
   - Função: Monitoramento de saúde

### CLIENTE
1. **db-forwarder** (gost)
   - Função: Forwarder para servidor VPN
   - Porta: 15432 (localhost)
   
2. **ts-client** (tailscale)
   - Função: Cliente VPN
   - Network: Compartilhada com db-forwarder
   
3. **connection-monitor** (alpine) [opcional]
   - Função: Monitoramento de conectividade

## 🌐 Rede e Conectividade

```
┌──────────────────────────────────────────────────────────────┐
│                         INTERNET                              │
└────────────┬─────────────────────────────┬───────────────────┘
             │                             │
             ↓                             ↓
      ┌─────────────┐               ┌─────────────┐
      │   SERVIDOR  │←──VPN Tunnel─→│   CLIENTE   │
      │             │   (Tailscale) │             │
      │ db-proxy    │               │ db-forward  │
      │ ts-server   │               │ ts-client   │
      └──────┬──────┘               └──────┬──────┘
             │                             │
             ↓                             ↓
      ┌─────────────┐               ┌─────────────┐
      │  BANCO DE   │               │  localhost  │
      │    DADOS    │               │   :15432    │
      │  EXTERNO    │               └──────┬──────┘
      └─────────────┘                      │
                                          ↓
                                   ┌─────────────┐
                                   │  DBeaver    │
                                   │  pgAdmin    │
                                   │  Apps       │
                                   └─────────────┘
```

## 📝 Notas Importantes

1. **TS_AUTHKEY** deve ser a mesma no servidor e cliente
2. **VPN_SERVER_IP** é obtido executando `docker exec ts-server tailscale ip`
3. **LOCAL_PORT** padrão é 15432 (evita conflito com PostgreSQL local na 5432)
4. **DB_HOST** deve ser acessível pela máquina do servidor
5. **Estado VPN** é persistente - manter backup em produção

## 🚀 Comandos Rápidos

### Iniciar Tudo
```bash
# Servidor
cd SERVER && docker-compose up -d

# Cliente  
cd CLIENT && docker-compose up -d
```

### Verificar Status
```bash
docker-compose ps                    # Status containers
docker exec ts-server tailscale ip   # IP do servidor
docker exec ts-client tailscale ping <SERVER_IP>  # Teste
```

### Ver Logs
```bash
docker-compose logs -f               # Todos
docker-compose logs ts-server        # Servidor VPN
docker-compose logs db-forwarder     # Forwarder
```

### Parar Tudo
```bash
docker-compose down                  # Em cada diretório
```