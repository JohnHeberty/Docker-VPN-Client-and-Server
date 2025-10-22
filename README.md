# 🔐 VPN Client-Server Database Proxy

Arquitetura completa de VPN para acesso seguro a bancos de dados remotos usando **Tailscale** e **Docker Compose**.

## 🎯 O que é?

Sistema que permite acessar bancos de dados externos de forma segura através de uma VPN criptografada, externalizando a conexão no `localhost` da máquina cliente.

```
[Banco Remoto] ←→ [VPN Server] ←→ [VPN Tunnel] ←→ [VPN Client] ←→ [localhost:15432]
                                                                          ↓
                                                              [DBeaver/Apps Locais]
```

## ✨ Características

- ✅ **Criptografia End-to-End** via Tailscale (WireGuard)
- ✅ **Zero Configuration** - Apenas configure `.env` e execute
- ✅ **Docker Compose** - Tudo em containers isolados
- ✅ **Multiplataforma** - Windows, Linux, MacOS
- ✅ **Monitoramento** - Health checks e logs estruturados
- ✅ **Segurança** - Sem exposição de portas externas

## 🚀 Quick Start

### 1. Configure o Servidor

```bash
cd SERVER
cp .env.example .env
# Edite .env com os dados do seu banco externo
docker-compose up -d

# Anote o IP da VPN
docker exec ts-server tailscale ip
```

### 2. Configure o Cliente

```bash
cd CLIENT
cp .env.example .env
# Edite .env com o IP do servidor VPN obtido acima
docker-compose up -d
```

### 3. Conecte suas Aplicações

```bash
# psql
psql -h localhost -p 15432 -U usuario -d database

# DBeaver: localhost:15432
# pgAdmin: localhost:15432
```

## 📁 Estrutura do Projeto

```
VPN_CLIENT_SERVER/
├── ARCHITECTURE.md       # Documentação completa da arquitetura
├── README.md            # Este arquivo
│
├── SERVER/              # Servidor VPN + Database Proxy
│   ├── compose.yaml
│   ├── compose.advanced.yaml
│   ├── .env.example
│   ├── README.md
│   ├── start.ps1
│   └── start.sh
│
└── CLIENT/              # Cliente VPN + Port Forwarder
    ├── compose.yaml
    ├── compose.advanced.yaml
    ├── .env.example
    ├── README.md
    ├── QUICK_START.md
    ├── start.ps1
    ├── start.sh
    ├── test-connection.ps1
    └── test-connection.sh
```

## 📖 Documentação

### Documentos Principais

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Arquitetura completa e fluxo de dados
- **[SERVER/README.md](SERVER/README.md)** - Documentação do servidor
- **[CLIENT/README.md](CLIENT/README.md)** - Documentação do cliente
- **[CLIENT/QUICK_START.md](CLIENT/QUICK_START.md)** - Guia rápido de conexão

### Scripts Disponíveis

#### SERVER

- **`start.ps1`** / **`start.sh`** - Inicializa o servidor VPN
  ```powershell
  cd SERVER
  .\start.ps1  # Windows
  ./start.sh   # Linux/Mac
  ```

#### CLIENT

- **`start.ps1`** / **`start.sh`** - Inicializa o cliente VPN
  ```powershell
  cd CLIENT
  .\start.ps1  # Windows
  ./start.sh   # Linux/Mac
  ```

- **`test-connection.ps1`** / **`test-connection.sh`** - Testa conectividade
  ```powershell
  cd CLIENT
  .\test-connection.ps1  # Windows
  ./test-connection.sh   # Linux/Mac
  ```

## ⚙️ Configuração Detalhada

### Servidor (.env)

```env
# Banco de dados externo
DB_HOST=your-database-host.com
DB_PORT=5432

# Tailscale
TS_AUTHKEY=tskey-auth-YOUR-KEY-HERE
```

### Cliente (.env)

```env
# IP do servidor VPN (obter do servidor)
VPN_SERVER_IP=100.94.199.41
VPN_SERVER_PORT=5432

# Porta local
LOCAL_PORT=15432

# Tailscale (mesma key do servidor)
TS_AUTHKEY=tskey-auth-YOUR-KEY-HERE
```

## 🔍 Verificação de Status

### Servidor

```bash
cd SERVER
docker-compose ps
docker exec ts-server tailscale status
docker exec ts-server tailscale ip
```

### Cliente

```bash
cd CLIENT
docker-compose ps
docker exec ts-client tailscale status
docker exec ts-client tailscale ping <VPN_SERVER_IP>
```

## 🛠️ Troubleshooting

### VPN não conecta

```bash
# Ver logs
docker-compose logs ts-server  # no servidor
docker-compose logs ts-client  # no cliente

# Verificar auth key
cat .env | grep TS_AUTHKEY
```

### Cliente não alcança servidor

```bash
# No cliente, testar ping
docker exec ts-client tailscale ping <VPN_SERVER_IP>

# Verificar se servidor está rodando
# No servidor
docker-compose ps
```

### Porta local não responde

```bash
# Verificar se está escutando
netstat -an | findstr 15432  # Windows
netstat -an | grep 15432     # Linux/Mac

# Ver logs do forwarder
docker-compose logs db-forwarder
```

## 🎨 Recursos Avançados

### Monitoramento

Use `compose.advanced.yaml` para recursos extras:

```bash
# Com monitoramento automático
docker-compose -f compose.advanced.yaml up -d

# Com backup de configuração
docker-compose -f compose.advanced.yaml --profile backup up -d
```

### Múltiplas Instâncias

Configure `HOSTNAME_SUFFIX` no `.env`:

```env
HOSTNAME_SUFFIX=prod-client
```

## 🔐 Segurança

- ✅ Conexão VPN criptografada (WireGuard/Tailscale)
- ✅ Banco não exposto diretamente na internet
- ✅ Cliente expõe apenas no localhost (127.0.0.1)
- ✅ Acesso controlado por chaves de autenticação
- ✅ Containers isolados

## 🎯 Casos de Uso

- **Desenvolvimento**: Acesso seguro a bancos de produção/staging
- **Analytics**: Conectar ferramentas BI (Tableau, Power BI, Metabase)
- **Debugging**: Ferramentas locais acessando dados remotos
- **Migration**: Sincronização de dados entre ambientes
- **Compliance**: Acesso auditável e criptografado

## 💡 Tecnologias

- **[Tailscale](https://tailscale.com/)** - VPN mesh baseada em WireGuard
- **[GOST](https://github.com/ginuerzh/gost)** - Proxy/Forwarder de portas
- **[Docker](https://www.docker.com/)** - Containerização
- **[Docker Compose](https://docs.docker.com/compose/)** - Orquestração

## 📝 Exemplos de Conexão

### PostgreSQL

```bash
psql -h localhost -p 15432 -U postgres -d mydb
```

### MySQL

```bash
mysql -h localhost -P 15432 -u root -p
```

### Python

```python
import psycopg2
conn = psycopg2.connect(
    host="localhost",
    port=15432,
    database="mydb",
    user="postgres",
    password="password"
)
```

### Node.js

```javascript
const { Client } = require('pg');
const client = new Client({
    host: 'localhost',
    port: 15432,
    database: 'mydb',
    user: 'postgres',
    password: 'password'
});
```

## 📞 Suporte

Para problemas ou dúvidas:

1. Verifique os logs: `docker-compose logs`
2. Teste conectividade: `./test-connection.ps1` (cliente)
3. Verifique status VPN: `docker exec ts-client tailscale status`
4. Consulte documentação específica em `SERVER/` e `CLIENT/`

## 📜 Licença

Este projeto é fornecido "como está" para fins educacionais e de desenvolvimento.

---

**Desenvolvido com ❤️ usando Tailscale + Docker**